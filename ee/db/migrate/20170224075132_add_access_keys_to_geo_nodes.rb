# rubocop:disable RemoveIndex
class AddAccessKeysToGeoNodes < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  class EncryptedData
    extend AttrEncrypted
    attr_accessor :data
    attr_encrypted :data,
                   key: Settings.attr_encrypted_db_key_base,
                   algorithm: 'aes-256-gcm',
                   mode: :per_attribute_iv,
                   encode: true
  end

  def up
    add_column :geo_nodes, :access_key, :string
    add_column :geo_nodes, :encrypted_secret_access_key, :string
    add_column :geo_nodes, :encrypted_secret_access_key_iv, :string

    add_concurrent_index :geo_nodes, :access_key

    populate_secret_keys
  end

  def down
    remove_index :geo_nodes, :access_key

    remove_column :geo_nodes, :access_key
    remove_column :geo_nodes, :encrypted_secret_access_key
    remove_column :geo_nodes, :encrypted_secret_access_key_iv
  end

  private

  def populate_secret_keys
    select_all("SELECT id FROM geo_nodes").each do |node|
      id = node['id']
      keys = Gitlab::Geo.generate_access_keys
      encrypted = EncryptedData.new
      encrypted.data = keys[:secret_access_key]

      query = %(
        UPDATE geo_nodes
        SET access_key = #{quote(keys[:access_key])},
        encrypted_secret_access_key = #{quote(encrypted.encrypted_data)},
        encrypted_secret_access_key_iv = #{quote(encrypted.encrypted_data_iv)}
        WHERE id = #{id}
      ).squish

      execute(query)
    end
  end
end
