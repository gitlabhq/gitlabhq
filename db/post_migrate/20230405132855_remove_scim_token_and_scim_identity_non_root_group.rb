# frozen_string_literal: true

class RemoveScimTokenAndScimIdentityNonRootGroup < Gitlab::Database::Migration[2.1]
  BATCH_SIZE = 500

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    each_batch_range('scim_oauth_access_tokens', scope: ->(table) { table.all }, of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM scim_identities
        WHERE scim_identities.group_id
        IN
        (
          SELECT namespaces.id FROM scim_oauth_access_tokens
          INNER JOIN namespaces ON namespaces.id=scim_oauth_access_tokens.group_id
          WHERE namespaces.type='Group' AND namespaces.parent_id IS NOT NULL
          AND scim_oauth_access_tokens.id BETWEEN #{min} AND #{max}
        );

        DELETE FROM scim_oauth_access_tokens
        USING namespaces
        WHERE namespaces.id=scim_oauth_access_tokens.group_id
        AND namespaces.type='Group' AND namespaces.parent_id IS NOT NULL
        AND scim_oauth_access_tokens.id BETWEEN #{min} AND #{max};
      SQL
    end
  end

  def down
    # noop
  end
end
