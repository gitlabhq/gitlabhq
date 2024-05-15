# frozen_string_literal: true

module Pajamas
  module Concerns
    module CheckboxRadioLabelWithHelpText
      def render_label_with_help_text
        form.label(method, formatted_label_options) { label_entry }
      end

      def render_label_tag_with_help_text
        label_tag(name, formatted_label_options) { label_entry }
      end

      private

      def label_entry
        if help_text_content
          content_tag(:span, label_content) +
            content_tag(:p, help_text_content, class: 'help-text', data: { testid: 'pajamas-component-help-text' })
        else
          content_tag(:span, label_content)
        end
      end

      def formatted_label_options
        format_options(
          options: label_options,
          css_classes: ['custom-control-label'],
          additional_options: { value: value }
        )
      end
    end
  end
end
