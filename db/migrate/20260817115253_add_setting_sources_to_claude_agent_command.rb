# frozen_string_literal: true

class AddSettingSourcesToClaudeAgentCommand < Gitlab::Database::Migration[2.3]
  milestone '19.4'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  OLD_FLAGS = '--permission-mode acceptEdits --verbose'
  NEW_FLAGS = "--permission-mode acceptEdits --setting-sources '' --verbose"

  THIRD_PARTY_FLOW_TYPE = 3 # Ai::Catalog::Item.item_types[:third_party_flow]
  GITLAB_MAINTAINED = 100 # Namespaces::VerifiedNamespace::VERIFICATION_LEVELS[:gitlab_maintained]

  def up
    execute(<<~SQL)
      UPDATE ai_catalog_item_versions AS versions
      SET definition = replace(versions.definition::text, #{quote(OLD_FLAGS)}, #{quote(NEW_FLAGS)})::jsonb,
          updated_at = NOW()
      FROM ai_catalog_items AS items
      WHERE items.id = versions.ai_catalog_item_id
        AND items.item_type = #{THIRD_PARTY_FLOW_TYPE}
        AND items.verification_level = #{GITLAB_MAINTAINED}
        AND versions.definition::text LIKE #{quote("%#{OLD_FLAGS}%")}
    SQL
  end

  def down
    # no-op
  end
end
