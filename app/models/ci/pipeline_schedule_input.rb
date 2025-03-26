# frozen_string_literal: true

module Ci
  class PipelineScheduleInput < Ci::ApplicationRecord
    MAX_VALUE_SIZE = ::Gitlab::Ci::Config::Interpolation::Access::MAX_ACCESS_BYTESIZE

    belongs_to :pipeline_schedule
    belongs_to :project

    before_validation :assign_project_id, on: :create

    validates :name, presence: true, length: { maximum: 255 }, uniqueness: { scope: :pipeline_schedule_id }

    # We validate the size of the serialized value because encryption is expensive.
    # The maximum permitted size is equivalent to the maximum size permitted for an interpolated input value.
    validate :value_does_not_exceed_max_size

    encrypts :value

    private

    def value_does_not_exceed_max_size
      return if Gitlab::Json.encode(value).size <= MAX_VALUE_SIZE

      errors.add(:value, "exceeds max serialized size: #{MAX_VALUE_SIZE} characters")
    end

    def assign_project_id
      self.project_id = pipeline_schedule&.project_id
    end
  end
end
