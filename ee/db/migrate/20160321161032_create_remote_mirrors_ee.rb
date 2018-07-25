# rubocop:disable Migration/Timestamps
class CreateRemoteMirrorsEE < ActiveRecord::Migration
  def up
    # When moving from CE to EE, remote_mirrors may already exist
    return if table_exists?(:remote_mirrors)

    create_table :remote_mirrors do |t|
      t.references :project, index: true, foreign_key: true
      t.string :url
      t.boolean :enabled, default: true
      t.string :update_status
      t.datetime :last_update_at
      t.datetime :last_successful_update_at
      t.string :last_error
      t.text :encrypted_credentials
      t.string :encrypted_credentials_iv
      t.string :encrypted_credentials_salt

      t.timestamps null: false
    end
  end

  def down
    drop_table :remote_mirrors if table_exists?(:remote_mirrors)
  end
end
