# frozen_string_literal: true

class PrepareCiBuildsConstraintsForListPartitioning < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_check_constraint(:ci_builds, 'partition_id = 100', 'partitioning_constraint', validate: false)
    prepare_async_check_constraint_validation(:ci_builds, name: 'partitioning_constraint')
  end

  def down
    unprepare_async_check_constraint_validation(:ci_builds, name: 'partitioning_constraint')
    remove_check_constraint(:ci_builds, 'partitioning_constraint')
  end
end
