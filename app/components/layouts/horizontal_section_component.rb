# frozen_string_literal: true

module Layouts
  class HorizontalSectionComponent < ViewComponent::Base
    # @param [Boolean] border
    # @param [Hash] options
    def initialize(border: true, options: {})
      @border = border
      @options = options
    end

    private

    renders_one :title
    renders_one :description
    renders_one :body

    def formatted_options
      @options.merge({ class: [('gl-border-b' if @border), @options[:class]].flatten.compact })
    end
  end
end
