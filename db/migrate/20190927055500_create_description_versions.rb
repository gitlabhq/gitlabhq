# frozen_string_literal: true

class CreateDescriptionVersions < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    create_table :description_versions do |t|
      t.timestamps_with_timezone
      t.references :issue, index: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.references :merge_request, index: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.references :epic, index: false, foreign_key: { on_delete: :cascade }, type: :integer
      t.text :description # rubocop:disable Migration/AddLimitToTextColumns
    end

    add_index :description_versions, :issue_id, where: 'issue_id IS NOT NULL'
    add_index :description_versions, :merge_request_id, where: 'merge_request_id IS NOT NULL'
    add_index :description_versions, :epic_id, where: 'epic_id IS NOT NULL'

    add_column :system_note_metadata, :description_version_id, :bigint
  end

  def down
    remove_column :system_note_metadata, :description_version_id

    drop_table :description_versions
  end
end
