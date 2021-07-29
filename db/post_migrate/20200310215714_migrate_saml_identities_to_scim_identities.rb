# frozen_string_literal: true

class MigrateSamlIdentitiesToScimIdentities < ActiveRecord::Migration[6.0]
  DOWNTIME = false

  class Identity < ActiveRecord::Base
    self.table_name = 'identities'

    include ::EachBatch
  end

  def up
    Identity
      .joins('INNER JOIN saml_providers ON saml_providers.id = identities.saml_provider_id')
      .where('saml_providers.group_id IN (SELECT group_id FROM scim_oauth_access_tokens)')
      .select('identities.extern_uid, identities.user_id, saml_providers.group_id, TRUE AS active,
              identities.created_at, CURRENT_TIMESTAMP AS updated_at')
      .each_batch do |batch|
        data_to_insert = batch.map do |record|
          record.attributes.extract!("extern_uid", "user_id", "group_id", "active", "created_at", "updated_at")
        end

        Gitlab::Database.main.bulk_insert(:scim_identities, data_to_insert, on_conflict: :do_nothing) # rubocop:disable Gitlab/BulkInsert
      end
  end

  def down
  end
end
