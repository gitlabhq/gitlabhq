# frozen_string_literal: true

module Ci
  class JobArtifactReport < Ci::ApplicationRecord
    include Ci::Partitionable

    MAX_VALIDATION_ERROR_LENGTH = 255

    self.table_name = :p_ci_job_artifact_reports
    self.primary_key = :job_artifact_id

    query_constraints :job_artifact_id, :partition_id
    partitionable scope: :job_artifact, partitioned: true

    belongs_to :job_artifact, ->(report) { in_partition(report) },
      class_name: 'Ci::JobArtifact', partition_foreign_key: :partition_id, inverse_of: :artifact_report

    validates :job_artifact, presence: true
    validates :validation_error, length: { maximum: MAX_VALIDATION_ERROR_LENGTH }
    validates :project_id, presence: true

    enum :status, { faulty: 0, validated: 1 }

    def validation_error=(value)
      super(value&.truncate(MAX_VALIDATION_ERROR_LENGTH))
    end
  end
end
