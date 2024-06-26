# frozen_string_literal: true

module Layouts
  class PageHeadingComponent < ViewComponent::Base
    # @param [String] heading
    # @param [Hash] options
    def initialize(heading, options: {})
      @heading = heading
      @options = options
    end

    renders_one :heading
    renders_one :actions
    renders_one :description
  end
end
