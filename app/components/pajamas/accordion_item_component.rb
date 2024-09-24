# frozen_string_literal: true

# Renders a accordion component
module Pajamas
  class AccordionItemComponent < Pajamas::Component
    delegate :sprite_icon, to: :helpers

    STATE_OPTIONS = [:opened, :closed].freeze

    # @param [String] title
    # @param [Symbol] state
    def initialize(title: nil, state: :closed)
      @title = title
      @state = filter_attribute(state.to_sym, STATE_OPTIONS)
    end

    def icon
      @state == :opened ? "chevron-down" : "chevron-right"
    end

    def body_class
      @state == :opened ? { class: 'show' } : {}
    end

    def expanded
      @state == :opened
    end
  end
end
