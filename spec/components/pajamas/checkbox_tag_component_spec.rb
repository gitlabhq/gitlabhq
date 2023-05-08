# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::CheckboxTagComponent, :aggregate_failures, type: :component do
  let_it_be(:name) { :view_diffs_file_by_file }
  let_it_be(:label) { "Show one file at a time on merge request's Changes tab" }
  let_it_be(:help_text) { 'Instead of all the files changed, show only one file at a time.' }

  context 'with default options' do
    before do
      render_inline(described_class.new(name: name)) do |c|
        c.with_label { label }
      end
    end

    include_examples 'it renders unchecked checkbox with value of `1`'
    include_examples 'it does not render help text'
  end

  context 'with custom options' do
    let_it_be(:value) { 'yes' }
    let_it_be(:checkbox_options) { { class: 'checkbox-foo-bar', checked: true } }
    let_it_be(:label_options) { { class: 'label-foo-bar' } }

    before do
      render_inline(
        described_class.new(
          name: name,
          value: value,
          checked: true,
          checkbox_options: checkbox_options,
          label_options: label_options
        )
      ) do |c|
        c.with_label { label }
      end
    end

    it 'renders checked checkbox with value of `yes`' do
      expect(page).to have_checked_field(label, with: value, class: checkbox_options[:class])
    end

    it 'adds CSS class to label' do
      expect(page).to have_selector('label.label-foo-bar')
    end
  end

  context 'with `help_text` slot' do
    before do
      render_inline(described_class.new(name: name)) do |c|
        c.with_label { label }
        c.with_help_text { help_text }
      end
    end

    include_examples 'it renders unchecked checkbox with value of `1`'
    include_examples 'it renders help text'
  end
end
