# frozen_string_literal: true

class FixGroupScimIdentities < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.9'

  BATCH_SIZE = 150

  def up
    group_scim_identities = define_batchable_model('group_scim_identities')
    group_scim_identities.each_batch(of: BATCH_SIZE) do |relation|
      execute <<~SQL
        UPDATE group_scim_identities
        SET active = scim_identities.active
        FROM scim_identities
        WHERE group_scim_identities.temp_source_id = scim_identities.id
        AND group_scim_identities.active <> scim_identities.active
        AND group_scim_identities.id in (#{relation.dup.reselect(:id).to_sql})
      SQL
    end
  end

  def down
    # no op
  end
end
