# frozen_string_literal: true

class TruncateOldCiBuildNamesPartitions < Gitlab::Database::Migration[2.3]
  disable_ddl_transaction!
  milestone '18.2'

  def up
    return unless Gitlab.com_except_jh? || Gitlab.dev_or_test_env?

    Gitlab::Database::PostgresPartitionedTable
      .find_by_name_in_current_schema('p_ci_build_names')
      .postgres_partitions
      .order(:name)
      .first(3)
      .each do |partition|
        truncate_tables!(partition.identifier)
      end
  end

  def down
    # no-op
  end
end
