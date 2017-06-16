# rubocop:disable Migration/Timestamps
class CreateIssueLinksTable < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :issue_links do |t|
      t.integer :source_id, null: false, index: true
      t.integer :target_id, null: false, index: true

      t.timestamps null: true
    end

    add_index :issue_links, [:source_id, :target_id], unique: true

    add_concurrent_foreign_key :issue_links, :issues, column: :source_id
    add_concurrent_foreign_key :issue_links, :issues, column: :target_id
  end

  def down
    drop_table :issue_links
  end
end
