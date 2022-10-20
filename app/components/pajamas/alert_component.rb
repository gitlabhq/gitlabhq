# frozen_string_literal: true

# Renders a GlAlert root element
module Pajamas
  class AlertComponent < Pajamas::Component
    # @param [String] title
    # @param [Symbol] variant
    # @param [Boolean] dismissible
    # @param [Boolean] show_icon
    # @param [Hash] alert_options
    # @param [Hash] close_button_options
    def initialize(
      title: nil, variant: :info, dismissible: true, show_icon: true,
      alert_options: {}, close_button_options: {})
      @title = title.presence
      @variant = filter_attribute(variant&.to_sym, VARIANT_ICONS.keys, default: :info)
      @dismissible = dismissible
      @show_icon = show_icon
      @alert_options = alert_options
      @close_button_options = close_button_options
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

    VARIANT_ICONS = {
      info: 'information-o',
      warning: 'warning',
      success: 'check-circle',
      danger: 'error',
      tip: 'bulb'
    }.freeze

    def icon
      VARIANT_ICONS[@variant]
    end

    def icon_classes
      "gl-alert-icon#{' gl-alert-icon-no-title' if @title.nil?}"
    end
  end
end
