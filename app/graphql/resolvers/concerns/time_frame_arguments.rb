# frozen_string_literal: true

module TimeFrameArguments
  extend ActiveSupport::Concern

  include TimeFrameHelpers

  included do
    argument :timeframe, Types::TimeframeInputType,
      required: false,
      description: 'List items overlapping the given timeframe.'
  end
end
