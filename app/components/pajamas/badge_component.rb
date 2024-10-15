# frozen_string_literal: true

module Pajamas
  class BadgeComponent < Pajamas::Component
    VARIANT_OPTIONS = [:muted, :neutral, :info, :success, :warning, :danger, :tier].freeze

    def initialize(
      text = nil,
      icon: nil,
      icon_classes: [],
      icon_only: false,
      href: nil,
      variant: :muted,
      **html_options
    )
      @text = text.presence
      @icon = icon.to_s.presence
      @icon_classes = Array.wrap(icon_classes)
      @icon_only = @icon && icon_only
      @href = href.presence
      @variant = filter_attribute(variant.to_sym, VARIANT_OPTIONS, default: :muted)
      @html_options = html_options
    end

    private

    delegate :sprite_icon, to: :helpers

    def badge_classes
      classes = ["gl-badge", "badge", "badge-pill", "badge-#{@variant}"]
      classes.push('!gl-px-2') if icon_only?
      classes.join(" ")
    end

    def icon_classes
      classes = %w[gl-icon gl-badge-icon] + @icon_classes
      classes.push("-gl-ml-2") if circular_icon?
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

    def has_icon?
      icon_only? || @icon.present?
    end

    def circular_icon?
      %w[issue-open-m issue-close].include?(@icon)
    end

    def html_options
      options = format_options(options: @html_options, css_classes: badge_classes)
      options.merge!({ aria: { label: text }, role: "img" }) if icon_only?
      options
    end
  end
end
