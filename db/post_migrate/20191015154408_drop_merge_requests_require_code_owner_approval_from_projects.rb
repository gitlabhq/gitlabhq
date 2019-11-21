# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class DropMergeRequestsRequireCodeOwnerApprovalFromProjects < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    remove_column :projects, :merge_requests_require_code_owner_approval, :boolean
  end

  def down
    add_column :projects, :merge_requests_require_code_owner_approval, :boolean

    add_concurrent_index(
      :projects,
      %i[archived pending_delete merge_requests_require_code_owner_approval],
      name: 'projects_requiring_code_owner_approval',
      where: '((pending_delete = false) AND (archived = false) AND (merge_requests_require_code_owner_approval = true))'
    )
  end
end
