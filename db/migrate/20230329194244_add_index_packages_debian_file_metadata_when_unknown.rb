# frozen_string_literal: true

class AddIndexPackagesDebianFileMetadataWhenUnknown < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  INDEX_NAME = 'i_pkgs_deb_file_meta_on_updated_at_package_file_id_when_unknown'
  UNKNOWN = 1

  def up
    add_concurrent_index :packages_debian_file_metadata, [:updated_at, :package_file_id],
      where: "file_type = #{UNKNOWN}", name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_debian_file_metadata, name: INDEX_NAME
  end
end
