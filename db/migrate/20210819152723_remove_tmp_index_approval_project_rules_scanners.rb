# frozen_string_literal: true

class RemoveTmpIndexApprovalProjectRulesScanners < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  disable_ddl_transaction!

  INDEX_NAME = 'tmp_index_approval_project_rules_scanners'

  def up
    remove_concurrent_index_by_name :approval_project_rules, INDEX_NAME
  end

  def down
    add_concurrent_index :approval_project_rules, :scanners, name: INDEX_NAME, using: :gin, where: "scanners @> '{cluster_image_scanning}'"
  end
end
