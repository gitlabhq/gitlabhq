# frozen_string_literal: true

module Gitlab
  module FormBuilders
    class GitlabUiFormBuilder < ActionView::Helpers::FormBuilder
      def submit(value = nil, options = {})
        if options[:pajamas_button]
          @template.render Pajamas::ButtonComponent.new(
            variant: :confirm,
            type: :submit,
            button_options: options.except(:pajamas_button)
          ) do
            value
          end
        else
          super
        end
      end

      def gitlab_ui_checkbox_component(
        method,
        label = nil,
        help_text: nil,
        checkbox_options: {},
        checked_value: '1',
        unchecked_value: '0',
        label_options: {},
        content_wrapper_options: {},
        &block
      )
        Pajamas::CheckboxComponent.new(
          form: self,
          method: method,
          label: label,
          help_text: help_text,
          checkbox_options: format_options(checkbox_options),
          checked_value: checked_value,
          unchecked_value: unchecked_value,
          label_options: format_options(label_options),
          content_wrapper_options: content_wrapper_options
        ).render_in(@template, &block)
      end

      def gitlab_ui_radio_component(
        method,
        value,
        label = nil,
        help_text: nil,
        radio_options: {},
        label_options: {},
        &block
      )
        Pajamas::RadioComponent.new(
          form: self,
          method: method,
          value: value,
          label: label,
          help_text: help_text,
          radio_options: format_options(radio_options),
          label_options: format_options(label_options)
        ).render_in(@template, &block)
      end

      def gitlab_ui_datepicker(method, options = {})
        @template.text_field @object_name, method, options.merge(class: "datepicker form-control gl-form-input")
      end

      private

      def format_options(options)
        objectify_options(options)
      end
    end
  end
end
