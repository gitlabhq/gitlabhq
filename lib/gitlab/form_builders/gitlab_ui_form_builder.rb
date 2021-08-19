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
          @template.check_box(
            @object_name,
            method,
            format_options(checkbox_options, ['custom-control-input']),
            checked_value,
            unchecked_value
          ) +
          @template.label(
            @object_name, method, format_options(label_options, ['custom-control-label'])
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
      end

      private

      def format_options(options, classes)
        classes << options[:class]

        objectify_options(options.merge({ class: classes.flatten.compact }))
      end
    end
  end
end
