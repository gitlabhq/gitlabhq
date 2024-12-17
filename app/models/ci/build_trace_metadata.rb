# frozen_string_literal: true

module Ci
  class BuildTraceMetadata < Ci::ApplicationRecord
    include Ci::Partitionable

    MAX_ATTEMPTS = 5
    self.table_name = :p_ci_build_trace_metadata
    self.primary_key = :build_id

    before_validation :set_project_id, on: :create

    belongs_to :build,
      ->(trace_metadata) { in_partition(trace_metadata) },
      class_name: 'Ci::Build',
      partition_foreign_key: :partition_id,
      inverse_of: :trace_metadata

    belongs_to :trace_artifact, # rubocop:disable Rails/InverseOf -- No clear relation to be used
      ->(metadata) { in_partition(metadata) },
      class_name: 'Ci::JobArtifact',
      partition_foreign_key: :partition_id

    partitionable scope: :build, partitioned: true

    validates :build, presence: true
    validates :archival_attempts, presence: true

    def self.find_or_upsert_for!(build_id, partition_id)
      record = find_by(build_id: build_id, partition_id: partition_id)
      return record if record

      upsert({ build_id: build_id, partition_id: partition_id }, unique_by: %w[build_id partition_id])
      find_by!(build_id: build_id, partition_id: partition_id)
    end

    # The job is retried around 5 times during the 7 days retention period for
    # trace chunks as defined in `Ci::BuildTraceChunks::RedisBase::CHUNK_REDIS_TTL`
    def can_attempt_archival_now?
      return false unless archival_attempts_available?
      return true unless last_archival_attempt_at

      (last_archival_attempt_at + backoff).past?
    end

    def archival_attempts_available?
      archival_attempts <= MAX_ATTEMPTS
    end

    def increment_archival_attempts!
      increment!(:archival_attempts, touch: :last_archival_attempt_at)
    end

    def track_archival!(trace_artifact_id, checksum)
      update!(trace_artifact_id: trace_artifact_id, checksum: checksum, archived_at: Time.current)
    end

    def archival_attempts_message
      if archival_attempts_available?
        'The job can not be archived right now.'
      else
        'The job is out of archival attempts.'
      end
    end

    def remote_checksum_valid?
      checksum.present? &&
        checksum == remote_checksum
    end

    private

    def backoff
      ::Gitlab::Ci::Trace::Backoff.new(archival_attempts).value_with_jitter
    end

    def set_project_id
      self.project_id ||= build&.project_id
    end
  end
end
