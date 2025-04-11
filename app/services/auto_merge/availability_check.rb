# frozen_string_literal: true

module AutoMerge # rubocop:disable Gitlab/BoundedContexts -- Existing module
  class AvailabilityCheck
    ABORT_REASONS = {
      forbidden: 'they do not have permission to merge the merge request.',
      mergeability_checks_failed: ->(check) {
        "the merge request cannot be merged. Failed mergeability check: #{check || 'unknown'}"
      },
      merge_trains_disabled: 'merge trains are disabled for this project.',
      missing_diff_head_pipeline: 'the pipeline associated with this merge request is missing or out of sync.',
      incomplete_diff_head_pipeline: 'the merge request currently has a pipeline in progress.',
      default: 'this merge request cannot be added to the merge train.'
    }.freeze

    def self.success
      new(
        status: :available
      )
    end

    def self.error(unavailable_reason:, unsuccessful_check: nil)
      new(
        status: :unavailable,
        unavailable_reason: unavailable_reason,
        unsuccessful_check: unsuccessful_check
      )
    end

    attr_reader :status, :unavailable_reason, :unsuccessful_check

    def initialize(status:, unavailable_reason: nil, unsuccessful_check: nil)
      self.status = status
      self.unavailable_reason = unavailable_reason
      self.unsuccessful_check = unsuccessful_check
    end

    def available?
      status == :available
    end

    def abort_message
      message = ABORT_REASONS[unavailable_reason] || ABORT_REASONS[:default]
      message.respond_to?(:call) ? message.call(unsuccessful_check) : message
    end

    private

    attr_writer :status, :unavailable_reason, :unsuccessful_check
  end
end
