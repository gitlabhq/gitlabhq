# frozen_string_literal: true

class BackfillPipelinesIdRangeOnCiPartitions < Gitlab::Database::Migration[2.3]
  restrict_gitlab_migration gitlab_schema: :gitlab_ci

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

      partition.update!(pipelines_id_range: min...upper)
      break if partition.current?
    end
  end

  def down
    Partition.update_all(pipelines_id_range: nil)
  end
end
