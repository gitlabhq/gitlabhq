# frozen_string_literal: true

class UpdateCodexAgentModelToGpt53 < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  OLD_MODEL = 'gpt-5.1-codex'
  NEW_MODEL = 'gpt-5.3-codex'

  THIRD_PARTY_FLOW_TYPE = 3 # Ai::Catalog::Item.item_types[:third_party_flow]
  GITLAB_MAINTAINED = 100 # Namespaces::VerifiedNamespace::VERIFICATION_LEVELS[:gitlab_maintained]

  def up
    # Rewrites the definition as text so both the parsed `commands` array (executed by
    # Ai::FlowTriggers::RunService) and the `yaml_definition` string (shown in the UI) are
    # updated in one pass. Scoped to GitLab-maintained external agents so customer-authored
    # definitions referencing the same model are left untouched: `verification_level` is set
    # only by our own seeding code, never from user input. The scope deliberately covers both
    # project-scoped items (as on GitLab.com) and instance-level items (as seeded by
    # Gitlab::Ai::Catalog::ThirdPartyFlows::Seeder on other instances).
    execute(<<~SQL)
      UPDATE ai_catalog_item_versions AS versions
      SET definition = replace(versions.definition::text, #{quote(OLD_MODEL)}, #{quote(NEW_MODEL)})::jsonb,
          updated_at = NOW()
      FROM ai_catalog_items AS items
      WHERE items.id = versions.ai_catalog_item_id
        AND items.item_type = #{THIRD_PARTY_FLOW_TYPE}
        AND items.verification_level = #{GITLAB_MAINTAINED}
        AND versions.definition::text LIKE #{quote("%#{OLD_MODEL}%")}
    SQL
  end

  def down
    # no-op: gpt-5.1-codex was shut down by OpenAI and removed from the AI Gateway, so
    # restoring it would re-break the agent, including on instances seeded after this deploy.
  end
end
