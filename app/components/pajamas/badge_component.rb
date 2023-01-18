# frozen_string_literal: true

module Pajamas
  class BadgeComponent < Pajamas::Component
    def initialize(
      text = nil,
      icon: nil,
      icon_classes: [],
      icon_only: false,
      href: nil,
      size: :md,
      variant: :muted,
      **html_options
    )
      @text = text.presence
      @icon = icon.to_s.presence
      @icon_classes = Array.wrap(icon_classes)
      @icon_only = @icon && icon_only
      @href = href.presence
      @size = filter_attribute(size.to_sym, SIZE_OPTIONS, default: :md)
      @variant = filter_attribute(variant.to_sym, VARIANT_OPTIONS, default: :muted)
      @html_options = html_options
    end

    SIZE_OPTIONS = [:sm, :md, :lg].freeze
    VARIANT_OPTIONS = [:muted, :neutral, :info, :success, :warning, :danger, :tier].freeze

    private

    delegate :sprite_icon, to: :helpers

    def badge_classes
      ["gl-badge", "badge", "badge-pill", "badge-#{@variant}", @size.to_s]
    end

    def icon_classes
      classes = %w[gl-icon gl-badge-icon] + @icon_classes
      classes.push("gl-mr-2") unless icon_only?
      classes.join(" ")
    end

    def icon_only?
      @icon_only
    end

    def link?
      @href.present?
    end

    # Determines the rendered text content.
    # The content slot takes presedence over the text param.
    def text
      content || @text
    end

    def badge_content
      if icon_only?
        sprite_icon(@icon, css_class: icon_classes)
      elsif @icon.present?
        sprite_icon(@icon, css_class: icon_classes) + text
      else
        text
      end
    end

    def html_options
      options = format_options(options: @html_options, css_classes: badge_classes)
      options.merge!({ aria: { label: text }, role: "img" }) if icon_only?
      options
    end
  end
end
