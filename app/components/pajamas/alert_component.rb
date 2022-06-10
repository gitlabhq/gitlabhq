# frozen_string_literal: true

# Renders a GlAlert root element
module Pajamas
  class AlertComponent < Pajamas::Component
    # @param [String] title
    # @param [Symbol] variant
    # @param [Boolean] dismissible
    # @param [Boolean] show_icon
    # @param [String] alert_class
    # @param [Hash] alert_data
    # @param [String] close_button_class
    # @param [Hash] close_button_data
    def initialize(
      title: nil, variant: :info, dismissible: true, show_icon: true,
      alert_class: nil, alert_data: {}, alert_options: {}, close_button_class: nil, close_button_data: {})
      @title = title
      @variant = variant
      @dismissible = dismissible
      @show_icon = show_icon
      @alert_class = alert_class
      @alert_data = alert_data
      @alert_options = alert_options
      @close_button_class = close_button_class
      @close_button_data = close_button_data
    end

    def base_class
      classes = ["gl-alert-#{@variant}"]
      classes.push('gl-alert-not-dismissible') unless @dismissible
      classes.push('gl-alert-no-icon') unless @show_icon

      classes.join(' ')
    end

    private

    delegate :sprite_icon, to: :helpers

    renders_one :body
    renders_one :actions

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
