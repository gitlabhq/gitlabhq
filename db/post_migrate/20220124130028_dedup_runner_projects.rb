# frozen_string_literal: true

class DedupRunnerProjects < Gitlab::Database::Migration[1.0]
  TABLE_NAME = :ci_runner_projects
  TMP_INDEX_NAME = 'tmp_unique_ci_runner_projects_by_runner_id_and_project_id'
  OLD_INDEX_NAME = 'index_ci_runner_projects_on_runner_id_and_project_id'
  INDEX_NAME = 'index_unique_ci_runner_projects_on_runner_id_and_project_id'
  BATCH_SIZE = 5000

  disable_ddl_transaction!

  module Ci
    class RunnerProject < ActiveRecord::Base
      include EachBatch

      self.table_name = 'ci_runner_projects'
    end
  end

  def up
    last_runner_project_record_id = Ci::RunnerProject.maximum(:id) || 0

    # This index will disallow further duplicates while we're deduplicating the data.
    add_concurrent_index(TABLE_NAME, [:runner_id, :project_id], where: "id > #{Integer(last_runner_project_record_id)}", unique: true, name: TMP_INDEX_NAME)

    Ci::RunnerProject.each_batch(of: BATCH_SIZE) do |relation|
      duplicated_runner_projects = Ci::RunnerProject
        .select('COUNT(*)', :runner_id, :project_id)
        .where('(runner_id, project_id) IN (?)', relation.select(:runner_id, :project_id))
        .group(:runner_id, :project_id)
        .having('COUNT(*) > 1')

      duplicated_runner_projects.each do |runner_project|
        deduplicate_item(runner_project)
      end
    end

    add_concurrent_index(TABLE_NAME, [:runner_id, :project_id], unique: true, name: INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, TMP_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, OLD_INDEX_NAME)
  end

  def down
    add_concurrent_index(TABLE_NAME, [:runner_id, :project_id], name: OLD_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, TMP_INDEX_NAME)
    remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
  end

  private

  def deduplicate_item(runner_project)
    runner_projects_records = Ci::RunnerProject
      .where(project_id: runner_project.project_id, runner_id: runner_project.runner_id)
      .order(updated_at: :asc)
      .to_a

    attributes = {}
    runner_projects_records.each do |runner_projects_record|
      params = runner_projects_record.attributes.except('id')
      attributes.merge!(params.compact)
    end

    ApplicationRecord.transaction do
      record_to_keep = runner_projects_records.pop
      records_to_delete = runner_projects_records

      Ci::RunnerProject.where(id: records_to_delete.map(&:id)).delete_all
      record_to_keep.update!(attributes)
    end
  end
end
