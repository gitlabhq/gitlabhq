# frozen_string_literal: true

module Layouts
  class CrudComponent < ViewComponent::Base
    # @param [String] title
    # @param [String] description
    # @param [Number] count
    # @param [String] icon
    # @param [String] icon_class
    # @param [String] toggle_text
    # @param [Hash] options
    # @param [Hash] count_options
    # @param [Hash] body_options
    # @param [Hash] form_options
    # @param [Hash] toggle_options
    # @param [Hash] footer_options
    # @param [Boolean] is_collapsible
    def initialize(
      title, description: nil, count: nil, icon: nil, icon_class: nil,
      toggle_text: nil, options: {}, count_options: {}, body_options: {},
      form_options: {}, toggle_options: {}, footer_options: {},
      is_collapsible: false
    )
      @title = title
      @description = description
      @count = count
      @icon = icon
      @icon_class = icon_class
      @toggle_text = toggle_text
      @options = options
      @count_options = count_options
      @body_options = body_options
      @form_options = form_options
      @toggle_options = toggle_options
      @footer_options = footer_options
      @is_collapsible = is_collapsible
    end

    renders_one :description
    renders_one :actions
    renders_one :body
    renders_one :form
    renders_one :footer
    renders_one :pagination

    def id
      @title.downcase.strip.gsub(" ", "-").gsub(/[^\w-]/, "") # rubocop:disable Performance/StringReplacement -- Not possible with tr
    end

    def options_attrs
      default_classes = [
        ('js-toggle-container' if @toggle_text),
        ('js-crud-collapsible-section' if @is_collapsible)
      ]
      @options.merge(default_attrs(@options, nil, default_classes))
    end

    def body_options_attrs
      default_testid = 'crud-body'
      default_classes = [
        ('gl-rounded-b-base' unless footer),
        ('js-crud-collapsible-content' if @is_collapsible)
      ]
      @body_options.merge(default_attrs(@body_options, default_testid, default_classes))
    end

    def icon_classes
      default_classes = ['gl-fill-icon-subtle']
      default_classes << @icon_class if @icon_class
      default_classes.join(' ')
    end

    def toggle_button_options_attrs
      default_testid = 'crud-action-toggle'
      default_classes = ['js-toggle-button js-toggle-content']
      @toggle_options.merge(default_attrs(@toggle_options, default_testid, default_classes))
    end

    def form_options_attrs
      default_testid = 'crud-form'
      default_classes = [
        ('js-toggle-content' if @toggle_text),
        ('gl-hidden' if @toggle_text && !@form_options[:form_errors]),
        ('js-crud-collapsible-content' if @is_collapsible)
      ]
      @form_options.merge(default_attrs(@form_options, default_testid, default_classes))
    end

    def footer_options_attrs
      default_testid = 'crud-footer'
      default_classes = [
        ('js-crud-collapsible-content' if @is_collapsible)
      ]
      @footer_options.merge(default_attrs(@footer_options, default_testid, default_classes))
    end

    delegate :sprite_icon, to: :helpers

    private

    def default_attrs(attrs, default_testid = nil, default_classes = [])
      data = attrs[:data] || {}
      data[:testid] = default_testid unless data[:testid]
      classes = attrs[:class] || ""

      {
        data: data,
        class: "#{classes} #{default_classes.join(' ')}"
      }
    end
  end
end
