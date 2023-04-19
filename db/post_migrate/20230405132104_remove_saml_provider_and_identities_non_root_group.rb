# frozen_string_literal: true

class RemoveSamlProviderAndIdentitiesNonRootGroup < Gitlab::Database::Migration[2.1]
  BATCH_SIZE = 500

  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  def up
    each_batch_range('saml_providers', scope: ->(table) { table.all }, of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM identities
        WHERE identities.saml_provider_id
        IN
        (
          SELECT saml_providers.id FROM saml_providers
          INNER JOIN namespaces ON namespaces.id=saml_providers.group_id
          AND namespaces.type='Group' AND namespaces.parent_id IS NOT NULL
          AND saml_providers.id BETWEEN #{min} AND #{max}
        );

        DELETE FROM saml_providers
        USING namespaces
        WHERE namespaces.id=saml_providers.group_id
        AND namespaces.type='Group' AND namespaces.parent_id IS NOT NULL
        AND saml_providers.id BETWEEN #{min} AND #{max};
      SQL
    end
  end

  def down
    # noop
  end
end
