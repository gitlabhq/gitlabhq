# frozen_string_literal: true

class CreatePackagesNugetMetadata < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  disable_ddl_transaction!

  LICENSE_URL_CONSTRAINT_NAME = 'packages_nuget_metadata_license_url_constraint'
  PROJECT_URL_CONSTRAINT_NAME = 'packages_nuget_metadata_project_url_constraint'
  ICON_URL_CONSTRAINT_NAME = 'packages_nuget_metadata_icon_url_constraint'

  def up
    unless table_exists?(:packages_nuget_metadata)
      with_lock_retries do
        create_table :packages_nuget_metadata, id: false do |t|
          t.references :package, primary_key: true, default: nil, index: false, foreign_key: { to_table: :packages_packages, on_delete: :cascade }, type: :bigint
          t.text :license_url
          t.text :project_url
          t.text :icon_url
        end
      end
    end

    add_text_limit :packages_nuget_metadata, :license_url, 255, constraint_name: LICENSE_URL_CONSTRAINT_NAME
    add_text_limit :packages_nuget_metadata, :project_url, 255, constraint_name: PROJECT_URL_CONSTRAINT_NAME
    add_text_limit :packages_nuget_metadata, :icon_url, 255, constraint_name: ICON_URL_CONSTRAINT_NAME
  end

  def down
    drop_table :packages_nuget_metadata
  end
end
