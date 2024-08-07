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
    def initialize(
      title, description: nil, count: nil, icon: nil, icon_class: nil,
      toggle_text: nil, options: {}, count_options: {}, body_options: {},
      form_options: {}, toggle_options: {}, footer_options: {}
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
    end

    renders_one :description
    renders_one :actions
    renders_one :body
    renders_one :form
    renders_one :footer
    renders_one :pagination

    def body_options_attrs
      default_testid = 'crud-body'
      default_classes = [
        ('gl-rounded-b-base' unless footer)
      ]
      @body_options.merge(default_attrs(@body_options, default_testid, default_classes))
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
        ('gl-hidden' if @toggle_text && !@form_options[:form_errors])
      ]
      @form_options.merge(default_attrs(@form_options, default_testid, default_classes))
    end

    def footer_options_attrs
      default_testid = 'crud-footer'
      @footer_options.merge(default_attrs(@footer_options, default_testid))
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
