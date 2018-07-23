# frozen_string_literal: true
class DeleteInconsistentInternalIdRecords < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  # This migration cleans up any inconsistent records in internal_ids.
  #
  # That is, it deletes records that track a `last_value` that is
  # smaller than the maximum internal id (usually `iid`) found in
  # the corresponding model records.

  def up
    disable_statement_timeout do
      delete_internal_id_records('issues', 'project_id')
      delete_internal_id_records('merge_requests', 'project_id', 'target_project_id')
      delete_internal_id_records('deployments', 'project_id')
      delete_internal_id_records('milestones', 'project_id')
      delete_internal_id_records('milestones', 'namespace_id', 'group_id')
      delete_internal_id_records('ci_pipelines', 'project_id')
    end
  end

  class InternalId < ActiveRecord::Base
    self.table_name = 'internal_ids'
    enum usage: { issues: 0, merge_requests: 1, deployments: 2, milestones: 3, epics: 4, ci_pipelines: 5 }
  end

  private

  def delete_internal_id_records(base_table, scope_column_name, base_scope_column_name = scope_column_name)
    sql = <<~SQL
      SELECT id FROM ( -- workaround for MySQL
       SELECT internal_ids.id FROM (
         SELECT #{base_scope_column_name} AS #{scope_column_name}, max(iid) as maximum_iid from #{base_table} GROUP BY #{scope_column_name}
       ) maxima JOIN internal_ids USING (#{scope_column_name})
       WHERE internal_ids.usage=#{InternalId.usages.fetch(base_table)} AND maxima.maximum_iid > internal_ids.last_value
      ) internal_ids
    SQL

    InternalId.where("id IN (#{sql})").tap do |ids| # rubocop:disable GitlabSecurity/SqlInjection
      say "Deleting internal_id records for #{base_table}: #{ids.pluck(:project_id, :last_value)}" unless ids.empty?
    end.delete_all
  end
end
