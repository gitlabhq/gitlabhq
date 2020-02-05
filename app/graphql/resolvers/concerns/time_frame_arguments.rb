# frozen_string_literal: true

module TimeFrameArguments
  extend ActiveSupport::Concern

  included do
    argument :start_date, Types::TimeType,
             required: false,
             description: 'List items within a time frame where items.start_date is between startDate and endDate parameters (endDate parameter must be present)'

    argument :end_date, Types::TimeType,
             required: false,
             description: 'List items within a time frame where items.end_date is between startDate and endDate parameters (startDate parameter must be present)'
  end

  def validate_timeframe_params!(args)
    return unless args[:start_date].present? || args[:end_date].present?

    error_message =
      if args[:start_date].nil? || args[:end_date].nil?
        "Both startDate and endDate must be present."
      elsif args[:start_date] > args[:end_date]
        "startDate is after endDate"
      end

    if error_message
      raise Gitlab::Graphql::Errors::ArgumentError, error_message
    end
  end
end
