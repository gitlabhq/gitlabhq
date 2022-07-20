# frozen_string_literal: true

module Pajamas
  class SpinnerComponent < Pajamas::Component
    # @param [String] class
    # @param [Symbol] color
    # @param [Boolean] inline
    # @param [String] label
    # @param [Symbol] size
    def initialize(class: '', color: :dark, inline: false, label: _("Loading"), size: :sm)
      @class = binding.local_variable_get(:class)
      @color = filter_attribute(color.to_sym, COLOR_OPTIONS)
      @inline = inline
      @label = label.presence
      @size = filter_attribute(size.to_sym, SIZE_OPTIONS)
    end

    private

    def spinner_class
      ["gl-spinner", "gl-spinner-#{@size}", "gl-spinner-#{@color}"]
    end

    COLOR_OPTIONS = [:light, :dark].freeze
    SIZE_OPTIONS = [:sm, :md, :lg, :xl].freeze
  end
end
