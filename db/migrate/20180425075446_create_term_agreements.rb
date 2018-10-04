class CreateTermAgreements < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    create_table :term_agreements do |t|
      t.references :term, index: true, null: false
      t.foreign_key :application_setting_terms, column: :term_id
      t.references :user, index: true, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :accepted, default: false, null: false

      t.timestamps_with_timezone null: false
    end

    add_index :term_agreements, [:user_id, :term_id],
              unique: true,
              name: 'term_agreements_unique_index'
  end

  def down
    # rubocop:disable Migration/RemoveIndex
    remove_index :term_agreements, name: 'term_agreements_unique_index'

    drop_table :term_agreements
  end
end
