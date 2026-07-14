# frozen_string_literal: true

module Pajamas
  class SelectComponent < Pajamas::Component
    WIDTH_OPTIONS = [:xs, :sm, :md, :lg, :xl].freeze

    # @param [String, Symbol] name
    # @param [Array, Hash] choices the choices, as accepted by `options_for_select`
    # @param [Object] selected the value(s) to pre-select
    # @param [Symbol] width one of WIDTH_OPTIONS, or nil for full width
    # @param [Hash] select_options HTML options for the `select` element
    # @param [Hash] wrapper_options HTML options for the wrapper element
    def initialize(
      name:,
      choices:,
      selected: nil,
      width: nil,
      select_options: {},
      wrapper_options: {})
      @name = name
      @choices = choices
      @selected = selected
      @width = filter_attribute(width&.to_sym, WIDTH_OPTIONS)
      @select_options = select_options
      @wrapper_options = wrapper_options
    end

    private

    attr_reader :name, :choices, :selected, :select_options, :wrapper_options

    def formatted_options
      options_for_select(choices, selected)
    end

    def formatted_wrapper_options
      format_options(options: wrapper_options, css_classes: wrapper_classes)
    end

    def formatted_select_options
      format_options(options: select_options, css_classes: %w[custom-select gl-form-select])
    end

    def wrapper_classes
      # rubocop:disable Tailwind/StringInterpolation -- gl-form-select-* are width modifiers, not utilities
      ['gl-form-select-wrapper', ("gl-form-select-#{@width}" if @width)].compact
      # rubocop:enable Tailwind/StringInterpolation
    end
  end
end
