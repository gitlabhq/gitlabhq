# frozen_string_literal: true

class AddMetadataColumnsToPackagesPyPiMetadata < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    with_lock_retries do
      add_column :packages_pypi_metadata, :metadata_version, :text, null: true, if_not_exists: true
      add_column :packages_pypi_metadata, :summary, :text, null: true, if_not_exists: true
      add_column :packages_pypi_metadata, :keywords, :text, null: true, if_not_exists: true
      add_column :packages_pypi_metadata, :author_email, :text, null: true, if_not_exists: true
      add_column :packages_pypi_metadata, :description, :text, null: true, if_not_exists: true
      add_column :packages_pypi_metadata, :description_content_type, :text, null: true, if_not_exists: true
    end

    add_text_limit :packages_pypi_metadata, :metadata_version, 16
    add_text_limit :packages_pypi_metadata, :summary, 255
    add_text_limit :packages_pypi_metadata, :keywords, 255
    add_text_limit :packages_pypi_metadata, :author_email, 2048
    add_text_limit :packages_pypi_metadata, :description, 4000
    add_text_limit :packages_pypi_metadata, :description_content_type, 128
  end

  def down
    with_lock_retries do
      remove_column :packages_pypi_metadata, :metadata_version, if_exists: true
      remove_column :packages_pypi_metadata, :summary, if_exists: true
      remove_column :packages_pypi_metadata, :keywords, if_exists: true
      remove_column :packages_pypi_metadata, :author_email, if_exists: true
      remove_column :packages_pypi_metadata, :description, if_exists: true
      remove_column :packages_pypi_metadata, :description_content_type, if_exists: true
    end
  end
end
