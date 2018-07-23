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
    disable_statement_timeout

    delete_internal_id_records('issues', 'project_id')
    delete_internal_id_records('merge_requests', 'project_id', 'target_project_id')
    delete_internal_id_records('deployments', 'project_id')
    delete_internal_id_records('milestones', 'project_id')
    delete_internal_id_records('milestones', 'namespace_id', 'group_id')
    delete_internal_id_records('ci_pipelines', 'project_id')
  end

  class InternalId < ActiveRecord::Base
    self.table_name = 'internal_ids'
    enum usage: { issues: 0, merge_requests: 1, deployments: 2, milestones: 3, epics: 4, ci_pipelines: 5 }
  end

  private

  def delete_internal_id_records(base_table, scope_column_name, base_scope_column_name = scope_column_name)
    sql = <<~SQL
       SELECT internal_ids.id FROM (
         SELECT #{base_scope_column_name} AS #{scope_column_name}, max(iid) as maximum_iid from #{base_table} GROUP BY #{scope_column_name}
       ) maxima JOIN internal_ids USING (#{scope_column_name})
       WHERE internal_ids.usage=#{usage_for(base_table)} AND maxima.maximum_iid > internal_ids.last_value
    SQL

    InternalId.transaction do
      ids = InternalId.where("id IN (#{sql})") # rubocop:disable GitlabSecurity/SqlInjection

      ids.each do |id|
        say "Deleting internal_id record for #{base_table}, project_id=#{id.project_id}, last_value=#{id.last_value}"
      end

      ids.destroy_all
    end
  end

  def usage_for(base_table)
    InternalId.usages[base_table] || raise("unknown base_table '#{base_table}'")
  end
end
