# frozen_string_literal: true

class MigrateDisableMergeTrainsValue < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  restrict_gitlab_migration gitlab_schema: :gitlab_main

  class Gate < MigrationRecord
    self.table_name = 'feature_gates'
  end

  UPDATE_QUERY = <<-SQL
    UPDATE project_ci_cd_settings SET merge_trains_enabled = :merge_trains_enabled
    WHERE project_id IN (:project_ids)
  SQL

  def update_merge_trains_enabled(project_ids, merge_trains_enabled)
    ApplicationRecord.connection.execute(
      ApplicationRecord.sanitize_sql([
        UPDATE_QUERY,
        {
          project_ids: project_ids,
          merge_trains_enabled: merge_trains_enabled.to_s.upcase
        }
      ])
    )
  end

  def get_project_ids
    project_ids = Gate.where(feature_key: :disable_merge_trains, key: 'actors').pluck('value')

    project_ids.filter_map do |project_id|
      # ensure actor is a project formatted correctly
      match = project_id.match(/Project:[0-9]+/)[0]
      # Extract the project id if there is an actor
      match ? project_id.gsub('Project:', '').to_i : nil
    end
  end

  def up
    project_ids = get_project_ids

    return unless project_ids

    update_merge_trains_enabled(project_ids, false)
  end

  def down
    project_ids = get_project_ids

    return unless project_ids

    update_merge_trains_enabled(project_ids, true)
  end
end
