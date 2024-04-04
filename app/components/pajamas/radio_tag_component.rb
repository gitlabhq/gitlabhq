# frozen_string_literal: true

# Renders a Pajamas compliant radio button element
module Pajamas
  class RadioTagComponent < Pajamas::Component
    include Pajamas::Concerns::CheckboxRadioLabelWithHelpText
    include Pajamas::Concerns::CheckboxRadioOptions

    renders_one :label
    renders_one :help_text

    def initialize(
      name:,
      value:,
      checked: false,
      label: nil,
      help_text: nil,
      label_options: {},
      radio_options: {}
    )
      @name = name
      @value = value
      @checked = checked
      @label_argument = label
      @help_text_argument = help_text
      @label_options = label_options
      @label_options[:for] ||= label_for(name, value)
      @input_options = radio_options
    end

    private

    attr_reader(
      :name,
      :value,
      :checked,
      :label_argument,
      :help_text_argument,
      :label_options,
      :input_options
    )

    def label_content
      label? ? label : label_argument
    end

    def help_text_content
      help_text? ? help_text : help_text_argument
    end

    def label_for(name, value)
      "#{sanitize_to_id(name)}_#{value}"
    end
  end
end
