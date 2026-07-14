# frozen_string_literal: true

module Ci
  class RuntimeEnvironment < Ci::ApplicationRecord
    include PartitionedTable

    # The environment behind a key is torn down after this TTL, so the row that
    # holds the key is disposable. Partitions are dropped once every record in
    # them is older than the TTL.
    # Read more https://gitlab.com/gitlab-com/content-sites/handbook/-/blob/2f8156f76b80d344b6b0c6c06332b40aa446068b/content/handbook/engineering/architecture/design-documents/runner_suspendable_environments/_index.md?plain=1#L67
    PARTITION_DURATION = 1.day
    PARTITION_CLEANUP_THRESHOLD = 7.days

    self.table_name = :p_ci_runtime_environments
    self.primary_key = :id
    self.sequence_name = :p_ci_runtime_environments_id_seq

    ignore_column :partition, remove_never: true

    belongs_to :project

    has_many :build_runtime_environments, class_name: 'Ci::BuildRuntimeEnvironment',
      inverse_of: :runtime_environment

    validates :environment_key, presence: true, length: { maximum: 512 }
    validates :project, presence: true

    scope :for_partition, ->(partition) { where(partition: partition) }

    partitioned_by :partition, strategy: :sliding_list,
      next_partition_if: ->(active_partition) { oldest_record_older_than?(active_partition, PARTITION_DURATION) },
      detach_partition_if: ->(partition) { detach_partition?(partition) }

    def self.detach_partition?(partition)
      !for_partition(partition.value)
        .where(arel_table[:created_at].gt(PARTITION_CLEANUP_THRESHOLD.ago))
        .exists?
    end

    def self.oldest_record_older_than?(partition, duration)
      oldest = for_partition(partition.value).order(:id).first

      oldest.present? && oldest.created_at < duration.ago
    end
  end
end
