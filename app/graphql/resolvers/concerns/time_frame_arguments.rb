# frozen_string_literal: true

module TimeFrameArguments
  extend ActiveSupport::Concern

  TIMEFRAME_LIMIT_YEARS = 3.5

  included do
    argument :timeframe, Types::TimeframeInputType,
      required: false,
      description: 'List items overlapping the given timeframe.'
  end

  def transform_timeframe_parameters(args)
    return {} unless args[:timeframe]

    args[:timeframe].to_h.transform_keys { |k| :"#{k}_date" }
  end

  def validate_timeframe_limit!(timeframe)
    return unless timeframe && timeframe[:start] && timeframe[:end]

    start_date = timeframe[:start]
    end_date = timeframe[:end]

    start_date = start_date.is_a?(String) ? Date.parse(start_date) : start_date
    end_date = end_date.is_a?(String) ? Date.parse(end_date) : end_date

    years_difference = (end_date - start_date).to_f / 365.25

    return unless years_difference > TIMEFRAME_LIMIT_YEARS

    raise Gitlab::Graphql::Errors::ArgumentError,
      format(_('Timeframe cannot exceed %{limit} years for work item queries'), limit: TIMEFRAME_LIMIT_YEARS)
  end
end
