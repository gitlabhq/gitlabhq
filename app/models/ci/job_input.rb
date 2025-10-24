# frozen_string_literal: true

module Ci
  # Stores input values for CI jobs.
  #
  # Records are only persisted when a job is retried with user-submitted input values.
  # On first run, jobs use default values from the input spec stored in options[:inputs],
  # and no Ci::JobInput records are created. This avoids storing unnecessary data since
  # most jobs use default values.
  #
  # The fallback logic to default values is implemented in:
  # - BuildRunnerPresenter#runner_inputs (for job execution)
  class JobInput < Ci::ApplicationRecord
    include Ci::Partitionable
    include BulkInsertSafe

    MAX_VALUE_SIZE = ::Gitlab::Ci::Config::Interpolation::Access::MAX_ACCESS_BYTESIZE

    self.table_name = :p_ci_job_inputs
    self.primary_key = :id

    ignore_columns %i[input_type sensitive], remove_with: '18.7', remove_after: '2025-12-01'

    partitionable scope: :job, partitioned: true

    belongs_to :job, ->(build_name) { in_partition(build_name) },
      class_name: 'Ci::Build', partition_foreign_key: :partition_id,
      inverse_of: :inputs

    belongs_to :project

    validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: [:job_id, :partition_id] }
    validates :project, presence: true
    validates :value, json_schema: { filename: 'ci_job_input_value', size_limit: 64.kilobytes }

    # The maximum permitted size is equivalent to the maximum size permitted for an interpolated input value.
    validate :value_does_not_exceed_max_size

    encrypts :value

    private

    def value_does_not_exceed_max_size
      return if Gitlab::Json.encode(value).size <= MAX_VALUE_SIZE

      errors.add(:value, "exceeds max serialized size: #{MAX_VALUE_SIZE} characters")
    end
  end
end
