# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::CheckboxComponent, :aggregate_failures, type: :component do
  include FormBuilderHelpers

  let_it_be(:method) { :view_diffs_file_by_file }
  let_it_be(:label) { "Show one file at a time on merge request's Changes tab" }
  let_it_be(:help_text) { 'Instead of all the files changed, show only one file at a time.' }

  context 'with default options' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            label: label
          )
        )
      end
    end

    include_examples 'it renders unchecked checkbox with value of `1`'
    include_examples 'it does not render help text'

    it 'renders hidden input with value of `0`' do
      expect(page).to have_field('user[view_diffs_file_by_file]', type: 'hidden', with: '0')
    end
  end

  context 'with custom options' do
    let_it_be(:checked_value) { 'yes' }
    let_it_be(:unchecked_value) { 'no' }
    let_it_be(:checkbox_options) { { class: 'checkbox-foo-bar', checked: true } }
    let_it_be(:label_options) { { class: 'label-foo-bar' } }
    let_it_be(:content_wrapper_options) { { class: 'wrapper-foo-bar' } }

    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            label: label,
            help_text: help_text,
            checked_value: checked_value,
            unchecked_value: unchecked_value,
            checkbox_options: checkbox_options,
            label_options: label_options,
            content_wrapper_options: content_wrapper_options
          )
        )
      end
    end

    include_examples 'it renders help text'

    it 'renders checked checkbox with value of `yes`' do
      expect(page).to have_checked_field(label, with: checked_value, class: checkbox_options[:class])
    end

    it 'adds CSS class to label' do
      expect(page).to have_selector('label.label-foo-bar')
    end

    it 'adds CSS class to wrapper' do
      expect(page).to have_selector('.gl-form-checkbox.wrapper-foo-bar')
    end

    it 'renders hidden input with value of `no`' do
      expect(page).to have_field('user[view_diffs_file_by_file]', type: 'hidden', with: unchecked_value)
    end
  end

  context 'with `label` slot' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method
          )
        ) do |c|
          c.with_label { label }
        end
      end
    end

    include_examples 'it renders unchecked checkbox with value of `1`'
  end

  context 'with `help_text` slot' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            label: label
          )
        ) do |c|
          c.with_help_text { help_text }
        end
      end
    end

    include_examples 'it renders unchecked checkbox with value of `1`'
    include_examples 'it renders help text'
  end

  context 'with `label` and `help_text` slots' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method
          )
        ) do |c|
          c.with_label { label }
          c.with_help_text { help_text }
        end
      end
    end

    include_examples 'it renders unchecked checkbox with value of `1`'
    include_examples 'it renders help text'
  end
end
