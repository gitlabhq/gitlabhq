# frozen_string_literal: true

class DeleteProjectCalloutThree < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!
  restrict_gitlab_migration gitlab_schema: :gitlab_main

  BATCH_SIZE = 1000
  ULTIMATE_FEATURE_REMOVAL_BANNER_FEATURE_NAME = 3

  def up
    each_batch_range('user_project_callouts', scope: ->(table) { table.all }, of: BATCH_SIZE) do |min, max|
      execute <<~SQL
        DELETE FROM user_project_callouts
        WHERE feature_name = #{ULTIMATE_FEATURE_REMOVAL_BANNER_FEATURE_NAME}
        AND id BETWEEN #{min} AND #{max}
      SQL
    end
  end

  def down
    # NO-OP
  end
end
