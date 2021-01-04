# frozen_string_literal: true

class AddUniquenessIndexToLabelTitleAndGroup < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  GROUP_AND_TITLE = [:group_id, :title]

  def up
    add_concurrent_index :labels, GROUP_AND_TITLE, where: "labels.project_id IS NULL", unique: true, name: "index_labels_on_group_id_and_title_unique"
    remove_concurrent_index :labels, GROUP_AND_TITLE, name: "index_labels_on_group_id_and_title"
  end

  def down
    add_concurrent_index :labels, GROUP_AND_TITLE, where: "labels.project_id IS NULL", unique: false, name: "index_labels_on_group_id_and_title"
    remove_concurrent_index :labels, GROUP_AND_TITLE, name: "index_labels_on_group_id_and_title_unique"
  end
end
