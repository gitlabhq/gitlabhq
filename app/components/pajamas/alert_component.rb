# frozen_string_literal: true

# Renders a GlAlert root element
module Pajamas
  class AlertComponent < Pajamas::Component
    # @param [String] title
    # @param [Symbol] variant
    # @param [Boolean] dismissible
    # @param [String] alert_class
    # @param [Hash] alert_data
    # @param [String] close_button_class
    # @param [Hash] close_button_data
    def initialize(
      title: nil, variant: :info, dismissible: true,
      alert_class: nil, alert_data: {}, close_button_class: nil, close_button_data: {})
      @title = title
      @variant = variant
      @dismissible = dismissible
      @alert_class = alert_class
      @alert_data = alert_data
      @close_button_class = close_button_class
      @close_button_data = close_button_data
    end

    private

    delegate :sprite_icon, to: :helpers

    ICONS = {
      info: 'information-o',
      warning: 'warning',
      success: 'check-circle',
      danger: 'error',
      tip: 'bulb'
    }.freeze

    def icon
      ICONS[@variant]
    end

    def icon_classes
      "gl-alert-icon#{' gl-alert-icon-no-title' if @title.nil?}"
    end
  end
end
