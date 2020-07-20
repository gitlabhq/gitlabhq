# frozen_string_literal: true

class AddUniquenessIndexToLabelTitleAndProject < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  PROJECT_AND_TITLE = [:project_id, :title]

  def up
    add_concurrent_index :labels, PROJECT_AND_TITLE, where: "labels.group_id IS NULL", unique: true, name: "index_labels_on_project_id_and_title_unique"
    remove_concurrent_index :labels, PROJECT_AND_TITLE, name: "index_labels_on_project_id_and_title"
  end

  def down
    add_concurrent_index :labels, PROJECT_AND_TITLE, where: "labels.group_id IS NULL", unique: false, name: "index_labels_on_project_id_and_title"
    remove_concurrent_index :labels, PROJECT_AND_TITLE, name: "index_labels_on_project_id_and_title_unique"
  end
end
