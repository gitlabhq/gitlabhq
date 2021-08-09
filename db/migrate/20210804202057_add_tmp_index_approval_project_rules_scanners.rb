# frozen_string_literal: true

# See https://docs.gitlab.com/ee/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddTmpIndexApprovalProjectRulesScanners < ActiveRecord::Migration[6.1]
  include Gitlab::Database::MigrationHelpers

  INDEX_NAME = 'tmp_index_approval_project_rules_scanners'

  disable_ddl_transaction!

  def up
    add_concurrent_index :approval_project_rules, :scanners, name: INDEX_NAME, using: :gin, where: "scanners @> '{cluster_image_scanning}'"
  end

  def down
    remove_concurrent_index_by_name :approval_project_rules, INDEX_NAME
  end
end
