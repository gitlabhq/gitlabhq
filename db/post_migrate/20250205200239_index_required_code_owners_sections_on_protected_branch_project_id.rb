# frozen_string_literal: true

class IndexRequiredCodeOwnersSectionsOnProtectedBranchProjectId < Gitlab::Database::Migration[2.2]
  milestone '17.9'
  disable_ddl_transaction!

  INDEX_NAME = 'index_required_code_owners_sections_on_protected_branch_project'

  def up
    add_concurrent_index :required_code_owners_sections, :protected_branch_project_id, name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :required_code_owners_sections, INDEX_NAME
  end
end
