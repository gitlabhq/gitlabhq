# frozen_string_literal: true

# Renders a GlAnimatedIcon
module Pajamas
  class AnimatedIconComponent < Pajamas::Component
    VARIANT_CLASSES = {
      current: 'gl-animated-icon-current',
      default: 'gl-animated-icon-default',
      subtle: 'gl-animated-icon-subtle',
      strong: 'gl-animated-icon-strong',
      disabled: 'gl-animated-icon-disabled',
      link: 'gl-animated-icon-link',
      info: 'gl-animated-icon-info',
      warning: 'gl-animated-icon-warning',
      danger: 'gl-animated-icon-danger',
      success: 'gl-animated-icon-success'
    }.freeze

    ICONS = [:chevron_down_up, :chevron_lg_down_up, :chevron_lg_right_down, :chevron_right_down, :smile,
      :duo_chat, :loader, :notifications, :sidebar, :sort, :star, :todo, :upload].freeze

    # @param [Symbol] icon
    # @param [Symbol] variant
    # @param [Boolean] is_on
    # @param [Hash] icon_options
    def initialize(icon: :chevron_down_up, variant: :current, is_on: false, icon_options: {})
      @icon = filter_attribute(icon.to_sym, ICONS)
      @variant = filter_attribute(variant&.to_sym, VARIANT_CLASSES.keys, default: :current)
      @is_on = is_on
      @icon_options = icon_options
    end

    def icon_class
      classes = [VARIANT_CLASSES[@variant]]
      classes.push('gl-animated-sort-icon') if @icon == :sort
      classes.push('gl-animated-icon-on') if @is_on
      classes.push('gl-animated-icon-off') unless @is_on
      classes.push(@icon_options[:class]) if @icon_options[:class]
      classes.join(' ')
    end
  end
end
