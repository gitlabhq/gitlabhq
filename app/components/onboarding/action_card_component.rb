# frozen_string_literal: true

module Onboarding
  class ActionCardComponent < Onboarding::Component
    VARIANT_OPTIONS = [:default, :success, :promo].freeze

    # @param [String] title
    # @param [String] description
    # @param [String] icon
    # @param [String] href
    # @param [Hash] html_options
    # @param [Hash] link_options

    def initialize(
      title: nil,
      description: nil,
      icon: nil,
      href: nil,
      link_options: {},
      **html_options
    )
      @title = title
      @description = description
      @icon = icon.to_s
      @href = href
      @html_options = html_options
      @link_options = link_options
    end

    private

    delegate :sprite_icon, to: :helpers
    renders_one :this_is_text

    def card_classes
      ["action-card"]
    end

    def card_icon
      @icon
    end

    def link?
      @href.present?
    end

    def html_options
      format_options(options: @html_options, css_classes: card_classes)
    end
  end
end
