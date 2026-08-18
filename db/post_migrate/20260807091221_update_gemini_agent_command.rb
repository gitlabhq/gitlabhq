# frozen_string_literal: true

class UpdateGeminiAgentCommand < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  restrict_gitlab_migration gitlab_schema: :gitlab_main_org

  # Develop with Gemini Agent, only exists on GitLab.com
  ITEM_ID = 2331

  OLD_COMMAND = 'gemini --yolo --debug --prompt'
  NEW_COMMAND = 'gemini --yolo --debug --skip-trust --model gemini-2.5-pro --prompt'

  def up
    return unless Gitlab.com_except_jh?

    # Rewrites the definition as text so both the parsed `commands` array and the
    # `yaml_definition` string shown in the UI are updated in one pass.
    execute(<<~SQL)
      UPDATE ai_catalog_item_versions
      SET definition = replace(definition::text, #{quote(OLD_COMMAND)}, #{quote(NEW_COMMAND)})::jsonb,
          updated_at = NOW()
      WHERE ai_catalog_item_id = #{ITEM_ID}
        AND definition::text LIKE #{quote("%#{OLD_COMMAND}%")}
    SQL
  end

  def down
    return unless Gitlab.com_except_jh?

    execute(<<~SQL)
      UPDATE ai_catalog_item_versions
      SET definition = replace(definition::text, #{quote(NEW_COMMAND)}, #{quote(OLD_COMMAND)})::jsonb,
          updated_at = NOW()
      WHERE ai_catalog_item_id = #{ITEM_ID}
        AND definition::text LIKE #{quote("%#{NEW_COMMAND}%")}
    SQL
  end
end
