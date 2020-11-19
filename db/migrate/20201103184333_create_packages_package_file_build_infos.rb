# frozen_string_literal: true

class CreatePackagesPackageFileBuildInfos < ActiveRecord::Migration[6.0]
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false

  def up
    unless table_exists?(:packages_package_file_build_infos)
      with_lock_retries do
        create_table :packages_package_file_build_infos do |t|
          t.references :package_file, index: true,
                                      null: false,
                                      foreign_key: { to_table: :packages_package_files, on_delete: :cascade },
                                      type: :bigint
          t.references :pipeline, index: true,
                                  null: true,
                                  foreign_key: { to_table: :ci_pipelines, on_delete: :nullify },
                                  type: :bigint
        end
      end
    end
  end

  def down
    with_lock_retries do
      drop_table :packages_package_file_build_infos
    end
  end
end
