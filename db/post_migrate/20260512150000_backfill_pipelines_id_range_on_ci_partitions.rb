# frozen_string_literal: true

class BackfillPipelinesIdRangeOnCiPartitions < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci
  disable_ddl_transaction!

  milestone '19.0'

  class Partition < MigrationRecord
    self.table_name = :ci_partitions

    def current?
      status == 2
    end
  end

  class Build < MigrationRecord
    self.table_name = :p_ci_builds
  end

  def up
    Partition.order(:id).to_a.push(Partition.new).each_cons(2) do |partition, next_partition|
      min = Build.where(partition_id: partition.id).minimum(:commit_id)
      next unless min

      upper = Build.where(partition_id: next_partition.id).minimum(:commit_id)

      # An empty next partition leaves a NULL upper bound, making this non-current
      # partition unbounded and overlapping the current one. Skip it; a partition
      # with no range just falls back to a full scan at lookup time.
      next if upper.nil? && !partition.current?

      begin
        partition.update!(pipelines_id_range: min...upper)
      rescue ActiveRecord::StatementInvalid => e
        # Tolerate only a range overlap, the failure this backfill exists to avoid;
        # let timeouts, deadlocks, and the like abort so they are not masked.
        raise unless e.cause.is_a?(PG::ExclusionViolation)

        say "Skipping partition #{partition.id}: #{e.message}"
      end

      break if partition.current?
    end
  end

  def down
    Partition.update_all(pipelines_id_range: nil)
  end
end
