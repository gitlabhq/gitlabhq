# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::Concerns::CheckboxRadioLabelWithHelpText do
  let(:form) { instance_double('ActionView::Helpers::FormBuilder') }
  let(:component_class) do
    Class.new do
      attr_reader(
        :form,
        :method,
        :name,
        :label_argument,
        :help_text_argument,
        :label_options,
        :input_options,
        :value
      )

      def initialize(
        form: nil,
        method: nil,
        name: nil,
        label: nil,
        help_text: nil,
        label_options: {},
        radio_options: {},
        value: nil
      )
        @form = form
        @method = method
        @name = name
        @label_argument = label
        @help_text_argument = help_text
        @label_options = label_options
        @input_options = radio_options
        @value = value
      end

      def label_content
        @label_argument
      end

      def help_text_content
        @help_text_argument
      end

      def format_options(options:, css_classes: [], additional_options: {})
        {}
      end

      include Pajamas::Concerns::CheckboxRadioLabelWithHelpText
      include ActionView::Context
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::FormTagHelper
    end
  end

  let_it_be(:method_or_name) { 'username' }
  let_it_be(:label_options) { { class: 'foo-bar' } }
  let_it_be(:value) { 'Foo bar' }
  let_it_be(:expected_label_entry) { '<span>Label argument</span>' }
  let_it_be(:expected_label_with_help_text_entry) do
    '<span>Label argument</span><p class="help-text" data-testid="pajamas-component-help-text">Help text argument</p>'
  end

  describe '#render_label_with_help_text' do
    it 'calls `#format_options` with correct arguments' do
      allow(form).to receive(:label)

      component = component_class.new(form: form, method: method_or_name, label_options: label_options, value: value)

      expect(component).to receive(:format_options).with(
        options: label_options,
        css_classes: ['custom-control-label'],
        additional_options: { value: value }
      )

      component.render_label_with_help_text
    end

    context 'when `help_text` argument is passed' do
      it 'calls `form.label` with `label` and `help_text` arguments used in the block' do
        component = component_class.new(
          form: form,
          method: method_or_name,
          label: 'Label argument',
          help_text: 'Help text argument'
        )

        expect(form).to receive(:label).with(method_or_name, {}) do |&block|
          expect(block.call).to eq(expected_label_with_help_text_entry)
        end

        component.render_label_with_help_text
      end
    end

    context 'when `help_text` argument is not passed' do
      it 'calls `form.label` with `label` argument used in the block' do
        component = component_class.new(
          form: form,
          method: method_or_name,
          label: 'Label argument'
        )

        expect(form).to receive(:label).with(method_or_name, {}) do |&block|
          expect(block.call).to eq(expected_label_entry)
        end

        component.render_label_with_help_text
      end
    end
  end

  describe '#render_label_tag_with_help_text' do
    it 'calls `#format_options` with correct arguments' do
      component = component_class.new(name: method_or_name, label_options: label_options, value: value)

      expect(component).to receive(:format_options).with(
        options: label_options,
        css_classes: ['custom-control-label'],
        additional_options: { value: value }
      )

      component.render_label_tag_with_help_text
    end

    context 'when `help_text` argument is passed' do
      it 'calls `label_tag` with `label` and `help_text` arguments used in the block' do
        component = component_class.new(
          name: method_or_name,
          label: 'Label argument',
          help_text: 'Help text argument'
        )

        expect(component).to receive(:label_tag).with(method_or_name, {}) do |&block|
          expect(block.call).to eq(expected_label_with_help_text_entry)
        end

        component.render_label_tag_with_help_text
      end
    end

    context 'when `help_text` argument is not passed' do
      it 'calls `label_tag` with `label` argument used in the block' do
        component = component_class.new(
          name: method_or_name,
          label: 'Label argument'
        )

        expect(component).to receive(:label_tag).with(method_or_name, {}) do |&block|
          expect(block.call).to eq(expected_label_entry)
        end

        component.render_label_tag_with_help_text
      end
    end
  end
end
