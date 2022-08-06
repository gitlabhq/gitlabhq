# frozen_string_literal: true

# Renders a Pajamas compliant checkbox element
module Pajamas
  class CheckboxTagComponent < Pajamas::Component
    include Pajamas::Concerns::CheckboxRadioLabelWithHelpText
    include Pajamas::Concerns::CheckboxRadioOptions

    renders_one :label
    renders_one :help_text

    def initialize(
      name:,
      label_options: {},
      checkbox_options: {},
      value: '1',
      checked: false
    )
      @name = name
      @label_options = label_options
      @input_options = checkbox_options
      @value = value
      @checked = checked
    end

    private

    attr_reader(
      :name,
      :label_options,
      :input_options,
      :value,
      :checked
    )

    def label_content
      label
    end

    def help_text_content
      help_text
    end
  end
end
