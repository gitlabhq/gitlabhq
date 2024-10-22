# frozen_string_literal: true

# Renders a GlAlert root element
module Pajamas
  class AlertComponent < Pajamas::Component
    VARIANT_ICONS = {
      info: 'information-o',
      warning: 'warning',
      success: 'check-circle',
      danger: 'error',
      tip: 'bulb'
    }.freeze

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
      classes = ["gl-alert-#{@variant}"] # rubocop:disable Tailwind/StringInterpolation -- Not a CSS utility class
      classes.push('gl-alert-not-dismissible') unless @dismissible
      classes.push('gl-alert-no-icon') unless @show_icon
      classes.push('gl-alert-has-title') if @title
      classes.join(' ')
    end

    private

    delegate :sprite_icon, to: :helpers

    renders_one :body
    renders_one :actions

    def icon
      VARIANT_ICONS[@variant]
    end

    def icon_classes
      "gl-alert-icon#{' gl-alert-icon-no-title' if @title.nil?}" # rubocop:disable Tailwind/StringInterpolation -- Not a CSS utility class
    end

    def dismissible_button_options
      new_options = @close_button_options.deep_symbolize_keys # in case strings were used
      new_options[:class] = "js-close gl-dismiss-btn #{new_options[:class]}"
      new_options[:aria] ||= {}
      new_options[:aria][:label] = _('Dismiss') # this will wipe out label if already present
      new_options
    end
  end
end
