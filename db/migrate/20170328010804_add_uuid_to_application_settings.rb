class AddUuidToApplicationSettings < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  def up
    add_column :application_settings, :uuid, :string
    execute("UPDATE application_settings SET uuid = #{quote(SecureRandom.uuid)}")
  end

  def down
    remove_column :application_settings, :uuid
  end
end
