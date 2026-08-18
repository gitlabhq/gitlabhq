# frozen_string_literal: true

class DisableVacuumTruncateOnUploadsPartitions < Gitlab::Database::Migration[2.3]
  milestone '19.3'

  disable_ddl_transaction!

  def up
    return unless Gitlab.com_except_jh?

    each_uploads_partition do |partition|
      with_lock_retries do
        execute("ALTER TABLE #{connection.quote_table_name(partition)} SET (vacuum_truncate = false)")
      end
    end
  end

  def down
    return unless Gitlab.com_except_jh?

    each_uploads_partition do |partition|
      with_lock_retries do
        execute("ALTER TABLE #{connection.quote_table_name(partition)} RESET (vacuum_truncate)")
      end
    end
  end

  private

  def each_uploads_partition
    Gitlab::Database::PostgresPartition.for_parent_table('uploads').each do |partition|
      yield partition.identifier
    end
  end
end
