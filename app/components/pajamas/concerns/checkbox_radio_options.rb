# frozen_string_literal: true

module Pajamas
  module Concerns
    module CheckboxRadioOptions
      def formatted_input_options
        format_options(options: input_options, css_classes: ['custom-control-input'])
      end
    end
  end
end
