# frozen_string_literal: true

# Renders a Pajamas compliant checkbox element
# An instance of `ActionView::Helpers::FormBuilder` must be passed as the `form` argument.
# The easiest way to use this component is by using the `gitlab_ui_checkbox_component` helper.
# See https://docs.gitlab.com/ee/development/fe_guide/haml.html#gitlab_ui_checkbox_component
# To use a checkbox without an instance of `ActionView::Helpers::FormBuilder` use `CheckboxTagComponent`.
module Pajamas
  class CheckboxComponent < Pajamas::Component
    include Pajamas::Concerns::CheckboxRadioLabelWithHelpText
    include Pajamas::Concerns::CheckboxRadioOptions

    renders_one :label
    renders_one :help_text

    def initialize(
      form:,
      method:,
      label: nil,
      help_text: nil,
      label_options: {},
      checkbox_options: {},
      content_wrapper_options: {},
      checked_value: '1',
      unchecked_value: '0'
    )
      @form = form
      @method = method
      @label_argument = label
      @help_text_argument = help_text
      @label_options = label_options
      @input_options = checkbox_options
      @content_wrapper_options = content_wrapper_options
      @checked_value = checked_value
      @unchecked_value = unchecked_value
      @value = checked_value if checkbox_options[:multiple]
    end

    private

    attr_reader(
      :form,
      :method,
      :label_argument,
      :help_text_argument,
      :label_options,
      :input_options,
      :content_wrapper_options,
      :checked_value,
      :unchecked_value,
      :value
    )

    def label_content
      label? ? label : label_argument
    end

    def help_text_content
      help_text? ? help_text : help_text_argument
    end
  end
end
