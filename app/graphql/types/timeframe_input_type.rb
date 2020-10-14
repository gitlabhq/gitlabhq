# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class TimeframeInputType < RangeInputType[::Types::DateType]
    graphql_name 'Timeframe'
    description 'A time-frame defined as a closed inclusive range of two dates'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
