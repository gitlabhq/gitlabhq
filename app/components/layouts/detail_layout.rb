# frozen_string_literal: true

module Layouts
  class DetailLayout < ViewComponent::Base
    # @param [String] heading
    # @param [String] description
    # @param [Hash] options
    def initialize(heading: nil, description: nil, page_heading_sr_only: false, loading: false, options: {})
      @heading = heading
      @description = description
      @page_heading_sr_only = page_heading_sr_only
      @loading = loading
      @options = options
    end

    renders_one :heading
    renders_one :description
    renders_one :actions
    renders_one :alerts
    renders_one :sidebar
  end
end
