# frozen_string_literal: true

class BackfillGitPushPipelineLimitApplicationSetting < Gitlab::Database::Migration[2.2]
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  milestone '18.0'

  def up
    # The limit is set to 4 by default per the previous implementation
    pipeline_limit = feature_flag_enabled? ? 0 : 4

    sql = <<~SQL
        UPDATE application_settings
        SET ci_cd_settings = jsonb_set(
          ci_cd_settings,
          '{git_push_pipeline_limit}',
          to_jsonb(#{pipeline_limit})
        )
    SQL

    execute(sql)
  end

  def down; end

  def feature_flag_enabled?
    sql = <<~SQL
      SELECT 1
      FROM feature_gates
      WHERE feature_key = 'git_push_create_all_pipelines'
      AND value = 'true'
      LIMIT 1;
    SQL

    result = execute(sql)

    # avoiding ActiveRecord::Base.connection and using a sql query
    # PG::Result responds to #ntuples, which is the number of rows returned
    result.ntuples > 0
  end
end
