# frozen_string_literal: true

module Layouts
  class IndexLayout < ViewComponent::Base
    # @param [String] heading
    # @param [String] description
    # @param [Hash] options
    def initialize(heading: nil, description: nil, options: {})
      @heading = heading
      @description = description
      @options = options
    end

    renders_one :heading
    renders_one :description
    renders_one :alerts
  end
end
