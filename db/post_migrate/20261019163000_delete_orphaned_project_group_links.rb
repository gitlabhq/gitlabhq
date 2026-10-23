# frozen_string_literal: true

class DeleteOrphanedProjectGroupLinks < Gitlab::Database::Migration[2.4]
  milestone '19.6'
  restrict_gitlab_migration gitlab_schema: :gitlab_main_org
  disable_ddl_transaction!

  BATCH_SIZE = 500

  def up
    project_group_links = define_batchable_model('project_group_links')
    namespaces = define_batchable_model('namespaces')

    # A link is orphaned when its group_id references a namespace that no longer exists
    # (fk_28a1244b01 is NOT VALID) or one that is not a group, such as a user namespace.
    project_group_links.distinct_each_batch(column: :group_id, of: BATCH_SIZE) do |batch|
      group_ids = batch.pluck(:group_id)
      valid_group_ids = namespaces.where(type: 'Group', id: group_ids).pluck(:id)
      orphaned_group_ids = group_ids - valid_group_ids
      next if orphaned_group_ids.empty?

      project_group_links.delete_by(group_id: orphaned_group_ids)
    end
  end

  def down
    # no-op - the deleted links did not reference a group, so they cannot be restored
  end
end
