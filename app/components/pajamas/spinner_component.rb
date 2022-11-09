# frozen_string_literal: true

module Pajamas
  class SpinnerComponent < Pajamas::Component
    # @param [Symbol] color
    # @param [Boolean] inline
    # @param [String] label
    # @param [Symbol] size
    def initialize(color: :dark, inline: false, label: _("Loading"), size: :sm, **html_options)
      @color = filter_attribute(color.to_sym, COLOR_OPTIONS)
      @inline = inline
      @label = label.presence
      @size = filter_attribute(size.to_sym, SIZE_OPTIONS)
      @html_options = html_options
    end

    COLOR_OPTIONS = [:light, :dark].freeze
    SIZE_OPTIONS = [:sm, :md, :lg, :xl].freeze

    private

    def spinner_class
      ["gl-spinner", "gl-spinner-#{@size}", "gl-spinner-#{@color} gl-vertical-align-text-bottom!"]
    end

    def html_options
      options = format_options(options: @html_options, css_classes: "gl-spinner-container")
      options[:role] = "status"
      options
    end
  end
end
