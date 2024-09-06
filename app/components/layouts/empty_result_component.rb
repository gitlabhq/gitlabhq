# frozen_string_literal: true

module Layouts
  class EmptyResultComponent < Pajamas::Component
    TYPE_OPTIONS = [:search, :filter].freeze

    # @param [Symbol] type
    # @param [Hash] html_options
    def initialize(
      type: :search,
      **html_options
    )
      @type = filter_attribute(type.to_sym, TYPE_OPTIONS, default: :search)
      @html_options = html_options
    end

    def filter?
      @type == :filter
    end

    def html_options
      format_options(options: @html_options)
    end
  end
end
