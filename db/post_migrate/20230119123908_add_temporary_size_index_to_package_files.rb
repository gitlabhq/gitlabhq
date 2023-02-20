# frozen_string_literal: true

class AddTemporarySizeIndexToPackageFiles < Gitlab::Database::Migration[2.1]
  INDEX_NAME = 'tmp_idx_package_files_on_non_zero_size'

  disable_ddl_transaction!

  def up
    # Temporary index to be removed in 16.0 https://gitlab.com/gitlab-org/gitlab/-/issues/386695
    add_concurrent_index :packages_package_files,
                         %i[package_id size],
                         where: 'size IS NOT NULL',
                         name: INDEX_NAME
  end

  def down
    remove_concurrent_index_by_name :packages_package_files, INDEX_NAME
  end
end
