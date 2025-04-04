# frozen_string_literal: true

class BackfillCiJobLiveTraceApplicationSetting < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.11'

  def up
    ci_enable_live_trace = Feature.enabled?(:ci_enable_live_trace,
      :instance) && Gitlab.config.artifacts.object_store.enabled

    sql = <<~SQL
      UPDATE application_settings
      SET ci_cd_settings = jsonb_set(
        ci_cd_settings,
        '{ci_job_live_trace_enabled}',
        to_jsonb(#{ci_enable_live_trace})
      )
    SQL

    execute(sql)
  end

  def down; end
end
