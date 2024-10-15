# frozen_string_literal: true

class RemoveConanInfoColumnsInPackagesConanMetadata < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.5'

  def up
    with_lock_retries do
      remove_column :packages_conan_metadata, :os, if_exists: true
      remove_column :packages_conan_metadata, :architecture, if_exists: true
      remove_column :packages_conan_metadata, :build_type, if_exists: true
      remove_column :packages_conan_metadata, :compiler, if_exists: true
      remove_column :packages_conan_metadata, :compiler_version, if_exists: true
      remove_column :packages_conan_metadata, :compiler_libcxx, if_exists: true
      remove_column :packages_conan_metadata, :compiler_cppstd, if_exists: true
    end
  end

  def down
    with_lock_retries do
      add_column :packages_conan_metadata, :os, :text, if_not_exists: true
      add_column :packages_conan_metadata, :architecture, :text, if_not_exists: true
      add_column :packages_conan_metadata, :build_type, :text, if_not_exists: true
      add_column :packages_conan_metadata, :compiler, :text, if_not_exists: true
      add_column :packages_conan_metadata, :compiler_version, :text, if_not_exists: true
      add_column :packages_conan_metadata, :compiler_libcxx, :text, if_not_exists: true
      add_column :packages_conan_metadata, :compiler_cppstd, :text, if_not_exists: true
    end

    add_text_limit :packages_conan_metadata, :os, 32
    add_text_limit :packages_conan_metadata, :architecture, 32
    add_text_limit :packages_conan_metadata, :build_type, 32
    add_text_limit :packages_conan_metadata, :compiler, 32
    add_text_limit :packages_conan_metadata, :compiler_version, 16
    add_text_limit :packages_conan_metadata, :compiler_libcxx, 32
    add_text_limit :packages_conan_metadata, :compiler_cppstd, 32
  end
end
