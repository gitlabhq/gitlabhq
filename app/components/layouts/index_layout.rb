# frozen_string_literal: true

module Layouts
  class IndexLayout < ViewComponent::Base
    # @param [String] heading
    # @param [String] description
    # @param [Hash] options
    def initialize(heading: nil, description: nil, page_heading_sr_only: false, options: {})
      @heading = heading
      @description = description
      @page_heading_sr_only = page_heading_sr_only
      @options = options
    end

    renders_one :heading
    renders_one :description
    renders_one :actions
    renders_one :alerts

    def page_heading_classes
      classes = '!gl-my-0 gl-pt-5'
      classes += ' gl-sr-only' if @page_heading_sr_only
      classes
    end
  end
end
