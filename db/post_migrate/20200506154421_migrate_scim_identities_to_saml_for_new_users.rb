# frozen_string_literal: true

class MigrateScimIdentitiesToSamlForNewUsers < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class ScimIdentity < ActiveRecord::Base
    self.table_name = 'scim_identities'

    belongs_to :user

    include ::EachBatch
  end

  class Identity < ActiveRecord::Base
    self.table_name = 'identities'

    belongs_to :saml_provider
  end

  def up
    users_with_saml_provider = Identity.select('user_id').joins(:saml_provider)

    ScimIdentity.each_batch do |relation|
      identity_records = relation
        .select("scim_identities.extern_uid, 'group_saml', scim_identities.user_id, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP, saml_providers.id")
        .joins(:user)
        .joins('inner join saml_providers on saml_providers.group_id=scim_identities.group_id')
        .where("date_trunc('second',scim_identities.created_at) at time zone 'UTC' = date_trunc('second',users.created_at)")
        .where.not(user_id: users_with_saml_provider)

      execute "insert into identities (extern_uid, provider, user_id, created_at, updated_at, saml_provider_id) #{identity_records.to_sql} on conflict do nothing"
    end
  end

  def down
  end
end
