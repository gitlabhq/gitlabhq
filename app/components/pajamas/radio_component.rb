# frozen_string_literal: true

# Renders a Pajamas compliant radio button element
# Must be used in an instance of `ActionView::Helpers::FormBuilder`
module Pajamas
  class RadioComponent < Pajamas::Component
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
      radio_options: {},
      value: nil
    )
      @form = form
      @method = method
      @label_argument = label
      @help_text_argument = help_text
      @label_options = label_options
      @input_options = radio_options
      @value = value
    end

    private

    attr_reader(
      :form,
      :method,
      :label_argument,
      :help_text_argument,
      :label_options,
      :input_options,
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
