class CreateUserSyncedAttributesMetadata < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def change
    create_table :user_synced_attributes_metadata do |t|
      t.boolean :name_synced, default: false
      t.boolean :email_synced, default: false
      t.boolean :location_synced, default: false
      t.references :user, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :provider
    end
  end
end
