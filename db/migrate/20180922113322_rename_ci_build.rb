# frozen_string_literal: true

class RenameCiBuild < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    rename_table_columns(
      :ci_builds,
      commit_id: :pipeline_id,
      environment: :environment_name,
      stage: :stage_name)
  end
end
