# frozen_string_literal: true

module Gitlab
  module FormBuilders
    class GitlabUiFormBuilder < ActionView::Helpers::FormBuilder
      def gitlab_ui_checkbox_component(
        method,
        label,
        help_text: nil,
        checkbox_options: {},
        checked_value: '1',
        unchecked_value: '0',
        label_options: {}
      )
        @template.content_tag(
          :div,
          class: 'gl-form-checkbox custom-control custom-checkbox'
        ) do
          value = checkbox_options[:multiple] ? checked_value : nil

          @template.check_box(
            @object_name,
            method,
            format_options(checkbox_options, ['custom-control-input']),
            checked_value,
            unchecked_value
          ) + generic_label(method, label, label_options, help_text: help_text, value: value)
        end
      end

      def gitlab_ui_radio_component(
        method,
        value,
        label,
        help_text: nil,
        radio_options: {},
        label_options: {}
      )
        @template.content_tag(
          :div,
          class: 'gl-form-radio custom-control custom-radio'
        ) do
          @template.radio_button(
            @object_name,
            method,
            value,
            format_options(radio_options, ['custom-control-input'])
          ) + generic_label(method, label, label_options, help_text: help_text, value: value)
        end
      end

      private

      def generic_label(method, label, label_options, help_text: nil, value: nil)
        @template.label(
          @object_name, method, format_options(label_options.merge({ value: value }), ['custom-control-label'])
        ) do
          if help_text
            @template.content_tag(
              :span,
              label
            ) +
            @template.content_tag(
              :p,
              help_text,
              class: 'help-text'
            )
          else
            label
          end
        end
      end

      def format_options(options, classes)
        classes << options[:class]

        objectify_options(options.merge({ class: classes.flatten.compact }))
      end
    end
  end
end
