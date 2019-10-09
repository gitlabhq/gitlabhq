# frozen_string_literal: true

class MigrateCodeOwnerApprovalStatusToProtectedBranchesInBatches < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  DOWNTIME = false
  BATCH_SIZE = 200

  class Project < ActiveRecord::Base
    include EachBatch

    self.table_name = 'projects'
    self.inheritance_column = :_type_disabled

    has_many :protected_branches
  end

  class ProtectedBranch < ActiveRecord::Base
    include EachBatch

    self.table_name = 'protected_branches'
    self.inheritance_column = :_type_disabled

    belongs_to :project
  end

  def up
    add_concurrent_index :projects, :id, name: "temp_active_projects_with_prot_branches", where: 'archived = false and pending_delete = false and merge_requests_require_code_owner_approval = true'

    ProtectedBranch
      .joins(:project)
      .where(projects: { archived: false, pending_delete: false, merge_requests_require_code_owner_approval: true })
      .each_batch(of: BATCH_SIZE) do |batch|
        batch.update_all(code_owner_approval_required: true)
      end

    remove_concurrent_index_by_name(:projects, "temp_active_projects_with_prot_branches")
  end

  def down
    # noop
    #
  end
end
