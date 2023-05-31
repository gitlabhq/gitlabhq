# frozen_string_literal: true

class RemoveFileMd5FromDebianProjectComponentFiles < Gitlab::Database::Migration[2.1]
  enable_lock_retries!

  def change
    remove_column :packages_debian_project_component_files, :file_md5, :bytea
  end
end
