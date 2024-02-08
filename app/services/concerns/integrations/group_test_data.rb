# frozen_string_literal: true

module Integrations
  module GroupTestData
    NoDataError = Class.new(ArgumentError)

    private

    def push_events_data
      Gitlab::DataBuilder::Push.sample_data
    end
  end
end
