# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::Concerns::CheckboxRadioOptions do
  let(:component_class) do
    Class.new do
      include Pajamas::Concerns::CheckboxRadioOptions

      attr_reader(:input_options)

      def initialize(input_options: {})
        @input_options = input_options
      end

      def format_options(options:, css_classes: [], additional_options: {})
        {}
      end
    end
  end

  describe '#formatted_input_options' do
    let_it_be(:input_options) { { class: 'foo-bar' } }

    it 'calls `#format_options` with correct arguments' do
      component = component_class.new(input_options: input_options)

      expect(component).to receive(:format_options).with(options: input_options, css_classes: ['custom-control-input'])

      component.formatted_input_options
    end
  end
end
