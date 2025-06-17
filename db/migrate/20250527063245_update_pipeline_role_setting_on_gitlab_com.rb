# frozen_string_literal: true

class UpdatePipelineRoleSettingOnGitlabCom < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.1'

  def up
    return unless Gitlab.com_except_jh?

    execute <<-SQL
      UPDATE application_settings
      SET ci_cd_settings = jsonb_set(
        ci_cd_settings,
        '{pipeline_variables_default_allowed}',
        to_jsonb(false)
      )
    SQL
  end

  def down
    return unless Gitlab.com_except_jh?

    execute <<-SQL
      UPDATE application_settings
      SET ci_cd_settings = jsonb_set(
        ci_cd_settings,
        '{pipeline_variables_default_allowed}',
        to_jsonb(true)
      )
    SQL
  end
end
