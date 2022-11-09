# frozen_string_literal: true

module Pajamas
  class BannerComponent < Pajamas::Component
    # @param [String] button_text
    # @param [String] button_link
    # @param [Boolean] embedded
    # @param [Symbol] variant
    # @param [String] svg_path
    # @param [Hash] banner_options
    # @param [Hash] button_options
    # @param [Hash] close_options
    def initialize(
      button_text: 'OK',
      button_link: '#',
      embedded: false,
      variant: :promotion,
      svg_path: nil,
      banner_options: {},
      button_options: {},
      close_options: {}
    )
      @button_text = button_text
      @button_link = button_link
      @embedded = embedded
      @variant = filter_attribute(variant.to_sym, VARIANT_OPTIONS, default: :promotion)
      @svg_path = svg_path.to_s
      @banner_options = banner_options
      @button_options = button_options
      @close_options = close_options
    end

    VARIANT_OPTIONS = [:introduction, :promotion].freeze

    private

    def banner_class
      classes = []
      classes.push('gl-border-none') if @embedded
      classes.push('gl-banner-introduction') if introduction?
      classes.join(' ')
    end

    def close_class
      if introduction?
        'btn-confirm btn-confirm-tertiary'
      else
        'btn-default btn-default-tertiary'
      end
    end

    delegate :sprite_icon, to: :helpers

    renders_one :title
    renders_one :illustration
    renders_one :primary_action
    renders_many :actions

    def introduction?
      @variant == :introduction
    end
  end
end
