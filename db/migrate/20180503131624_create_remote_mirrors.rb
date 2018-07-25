class CreateRemoteMirrors < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    return if table_exists?(:remote_mirrors)

    create_table :remote_mirrors do |t|
      t.references :project, index: true, foreign_key: { on_delete: :cascade }
      t.string :url
      t.boolean :enabled, default: true
      t.string :update_status
      t.datetime :last_update_at
      t.datetime :last_successful_update_at
      t.datetime :last_update_started_at
      t.string :last_error
      t.boolean :only_protected_branches, default: false, null: false
      t.string :remote_name
      t.text :encrypted_credentials
      t.string :encrypted_credentials_iv
      t.string :encrypted_credentials_salt

      # rubocop:disable Migration/Timestamps
      t.timestamps null: false
    end
  end

  def down
    # ee/db/migrate/20160321161032_create_remote_mirrors_ee.rb will remove the table
  end
end
