# frozen_string_literal: true

module Pajamas
  class ButtonComponent < Pajamas::Component
    # @param [Symbol] category
    # @param [Symbol] variant
    # @param [Symbol] size
    # @param [Symbol] type
    # @param [Boolean] disabled
    # @param [Boolean] loading
    # @param [Boolean] block
    # @param [Boolean] selected
    # @param [String] icon
    # @param [String] href
    # @param [Boolean] form
    # @param [String] target
    # @param [Symbol] method
    # @param [Hash] button_options
    # @param [String] button_text_classes
    # @param [String] icon_classes
    def initialize(
      category: :primary,
      variant: :default,
      size: :medium,
      type: :button,
      disabled: false,
      loading: false,
      block: false,
      selected: false,
      icon: nil,
      href: nil,
      form: false,
      target: nil,
      method: nil,
      button_options: {},
      button_text_classes: nil,
      icon_classes: nil
    )
      @category = filter_attribute(category.to_sym, CATEGORY_OPTIONS)
      @variant = filter_attribute(variant.to_sym, VARIANT_OPTIONS)
      @size = filter_attribute(size.to_sym, SIZE_OPTIONS)
      @type = filter_attribute(type.to_sym, TYPE_OPTIONS, default: :button)
      @disabled = disabled
      @loading = loading
      @block = block
      @selected = selected
      @icon = icon
      @href = href
      @form = form
      @target = filter_attribute(target, TARGET_OPTIONS)
      @method = filter_attribute(method, METHOD_OPTIONS)
      @button_options = button_options
      @button_text_classes = button_text_classes
      @icon_classes = icon_classes
    end

    private

    def button_class
      classes = ['gl-button btn']
      classes.push('disabled') if @disabled || @loading
      classes.push('selected') if @selected
      classes.push('btn-block') if @block
      classes.push('btn-icon') if @icon && !content

      classes.push(SIZE_CLASSES[@size])

      classes.push(VARIANT_CLASSES[@variant])

      unless NON_CATEGORY_VARIANTS.include?(@variant) || @category == :primary
        classes.push("#{VARIANT_CLASSES[@variant]}-#{CATEGORY_CLASSES[@category]}")
      end

      classes.push(@button_options[:class])

      classes.join(' ')
    end

    CATEGORY_OPTIONS = [:primary, :secondary, :tertiary].freeze
    VARIANT_OPTIONS = [:default, :confirm, :danger, :dashed, :link, :reset].freeze
    SIZE_OPTIONS = [:small, :medium].freeze
    TYPE_OPTIONS = [:button, :reset, :submit].freeze
    TARGET_OPTIONS = %w[_self _blank _parent _top].freeze
    METHOD_OPTIONS = [:get, :post, :put, :delete, :patch].freeze

    CATEGORY_CLASSES = {
      primary: '',
      secondary: 'secondary',
      tertiary: 'tertiary'
    }.freeze

    VARIANT_CLASSES = {
      default: 'btn-default',
      confirm: 'btn-confirm',
      danger: 'btn-danger',
      dashed: 'btn-dashed',
      link: 'btn-link',
      reset: 'btn-gl-reset'
    }.freeze

    NON_CATEGORY_VARIANTS = [:dashed, :link, :reset].freeze

    SIZE_CLASSES = {
      small: 'btn-sm',
      medium: 'btn-md'
    }.freeze

    delegate :sprite_icon, to: :helpers
    delegate :gl_loading_icon, to: :helpers

    def link?
      @href.present?
    end

    def form?
      @href.present? && @form.present?
    end

    def base_attributes
      attributes = {}

      attributes['disabled'] = 'disabled' if @disabled || @loading
      attributes['aria-disabled'] = true if @disabled || @loading
      attributes['type'] = @type unless @href

      attributes
    end
  end
end
