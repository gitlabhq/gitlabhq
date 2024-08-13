# frozen_string_literal: true

module Pajamas
  class BadgeComponentPreview < ViewComponent::Preview
    # Badge
    # ---
    #
    # See its design reference [here](https://design.gitlab.com/components/badge).
    #
    # @param icon select [~, star-o, issue-closed, tanuki]
    # @param icon_only toggle
    # @param href url
    # @param text text
    # @param variant select {{ Pajamas::BadgeComponent::VARIANT_OPTIONS }}
    def default(icon: :tanuki, icon_only: false, href: nil, text: "Tanuki", variant: :muted)
      render Pajamas::BadgeComponent.new(
        text,
        icon: icon,
        icon_only: icon_only,
        href: href,
        variant: variant
      )
    end

    # Using the content slot
    # ---
    #
    # Use the content slot instead of the `text` param when things get more complicated than a plain string.
    # All other options (`icon`, etc.) work as usual.
    def slot
      render Pajamas::BadgeComponent.new(variant: :info) do
        "!ereht olleh".reverse.capitalize
      end
    end

    # Custom HTML attributes and icon classes
    # ---
    #
    # Any extra options passed into the component are treated as HTML attributes.
    # This makes adding data or an id easy.
    #
    # CSS classes provided with the `class:` option are combined with the component classes.
    #
    # It is also possible to set custom `icon_classes:`.
    #
    # The order in which you provide these keywords doesn't matter.
    def custom
      render Pajamas::BadgeComponent.new(
        "I'm special.",
        class: "js-special-badge",
        data: { count: 1 },
        icon: :tanuki,
        icon_classes: ["js-special-badge-icon"],
        id: "special-badge-22",
        variant: :success
      )
    end

    # Circular issuable status icons
    # ---
    #
    # Circular icons 'issue-open-m' and 'issue-close'
    def circular_icons
      render Pajamas::BadgeComponent.new(variant: :success, icon: 'issue-open-m') do
        'With status open'
      end

      render Pajamas::BadgeComponent.new(variant: :info, icon: 'issue-close') do
        'With status closed'
      end
    end

    # Icon only
    # ---
    #
    # Uses an icon only.
    def icon_only
      render Pajamas::BadgeComponent.new(variant: :success, icon: 'calendar')
    end
  end
end
