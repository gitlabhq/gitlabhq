# frozen_string_literal: true

class BackfillCiJobLiveTraceApplicationSetting < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '17.11'

  def up
    ci_enable_live_trace = feature_flag_enabled? && Gitlab.config.artifacts.object_store.enabled

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

  def feature_flag_enabled?
    sql = <<~SQL
    SELECT 1
    FROM feature_gates
    WHERE feature_key = 'ci_enable_live_trace'
    AND value = 'true'
    LIMIT 1;
    SQL

    result = execute(sql)

    # avoiding ActiveRecord::Base.connection and using a sql query
    # PG::Result responds to #ntuples, which is the number of rows returned
    result.ntuples > 0
  end
end
