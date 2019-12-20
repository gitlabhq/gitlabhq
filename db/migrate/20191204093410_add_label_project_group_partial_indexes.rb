# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddLabelProjectGroupPartialIndexes < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  PROJECT_AND_TITLE = [:project_id, :title]
  GROUP_AND_TITLE = [:group_id, :title]

  def up
    add_concurrent_index :labels, PROJECT_AND_TITLE, unique: false, where: "labels.group_id = null"
    add_concurrent_index :labels, GROUP_AND_TITLE, unique: false, where: "labels.project_id = null"
  end

  def down
    remove_concurrent_index :labels, PROJECT_AND_TITLE
    remove_concurrent_index :labels, GROUP_AND_TITLE
  end
end
