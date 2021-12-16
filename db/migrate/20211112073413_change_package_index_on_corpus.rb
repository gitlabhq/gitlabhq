# frozen_string_literal: true

class ChangePackageIndexOnCorpus < Gitlab::Database::Migration[1.0]
  INDEX_NAME = 'index_coverage_fuzzing_corpuses_on_package_id'

  disable_ddl_transaction!

  # Changing this index is safe.
  # The table does not have any data in it as it's behind a feature flag.
  def up
    remove_concurrent_index :coverage_fuzzing_corpuses, :package_id, name: INDEX_NAME
    add_concurrent_index :coverage_fuzzing_corpuses, :package_id, unique: true, name: INDEX_NAME
  end

  def down
    remove_concurrent_index :coverage_fuzzing_corpuses, :package_id, name: INDEX_NAME
    add_concurrent_index :coverage_fuzzing_corpuses, :package_id, name: INDEX_NAME
  end
end
