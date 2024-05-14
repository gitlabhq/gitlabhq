# frozen_string_literal: true

class RemoveUniqueIndexForMlModelPackagesOnProjectIdNameVersion < Gitlab::Database::Migration[2.2]
  disable_ddl_transaction!
  milestone '17.0'

  def up
    remove_concurrent_index_by_name :packages_packages, 'uniq_idx_packages_packages_on_project_id_name_version_ml_model'
  end

  def down
    # NOOP, this reading this index could cause errors when there are packages pending destruction
  end
end
