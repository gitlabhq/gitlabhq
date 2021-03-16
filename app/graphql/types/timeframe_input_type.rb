# frozen_string_literal: true

module Types
  class TimeframeInputType < RangeInputType[::Types::DateType]
    graphql_name 'Timeframe'
    description 'A time-frame defined as a closed inclusive range of two dates'
  end
end
