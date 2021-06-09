# frozen_string_literal: true

module TimeFrameArguments
  extend ActiveSupport::Concern

  OVERLAPPING_TIMEFRAME_DESC = 'List items overlapping a time frame defined by startDate..endDate (if one date is provided, both must be present)'

  included do
    argument :start_date, Types::TimeType,
             required: false,
             description: OVERLAPPING_TIMEFRAME_DESC,
             deprecated: { reason: 'Use timeframe.start', milestone: '13.5' }

    argument :end_date, Types::TimeType,
             required: false,
             description: OVERLAPPING_TIMEFRAME_DESC,
             deprecated: { reason: 'Use timeframe.end', milestone: '13.5' }

    argument :timeframe, Types::TimeframeInputType,
             required: false,
             description: 'List items overlapping the given timeframe.'
  end

  # TODO: remove when the start_date and end_date arguments are removed
  def validate_timeframe_params!(args)
    return unless %i[start_date end_date timeframe].any? { |k| args[k].present? }
    return if args[:timeframe] && %i[start_date end_date].all? { |k| args[k].nil? }

    error_message =
      if args[:timeframe].present?
        "startDate and endDate are deprecated in favor of timeframe. Please use only timeframe."
      elsif args[:start_date].nil? || args[:end_date].nil?
        "Both startDate and endDate must be present."
      elsif args[:start_date] > args[:end_date]
        "startDate is after endDate"
      end

    if error_message
      raise Gitlab::Graphql::Errors::ArgumentError, error_message
    end
  end

  def transform_timeframe_parameters(args)
    if args[:timeframe]
      args[:timeframe].transform_keys { |k| :"#{k}_date" }
    else
      args.slice(:start_date, :end_date)
    end
  end
end
