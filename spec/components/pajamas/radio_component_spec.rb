# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::RadioComponent, :aggregate_failures, type: :component do
  include FormBuilderHelpers

  let_it_be(:method) { :access_level }
  let_it_be(:label) { "Access Level" }
  let_it_be(:value) { :regular }
  let_it_be(:help_text) do
    'Administrators have access to all groups, projects, and users and can manage all features in this installation'
  end

  RSpec.shared_examples 'it renders unchecked radio' do
    it 'renders unchecked radio' do
      expect(page).to have_unchecked_field(label)
    end
  end

  context 'with default options' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            value: value,
            label: label
          )
        )
      end
    end

    include_examples 'it renders unchecked radio'
    include_examples 'it does not render help text'
  end

  context 'with custom options' do
    let_it_be(:radio_options) { { class: 'radio-foo-bar', checked: true } }
    let_it_be(:label_options) { { class: 'label-foo-bar' } }

    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            value: method,
            label: label,
            help_text: help_text,
            radio_options: radio_options,
            label_options: label_options
          )
        )
      end
    end

    include_examples 'it renders help text'

    it 'renders checked radio' do
      expect(page).to have_checked_field(label, class: radio_options[:class])
    end

    it 'adds CSS class to label' do
      expect(page).to have_selector('label.label-foo-bar')
    end
  end

  context 'with `label` slot' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            value: value
          )
        ) do |c|
          c.with_label { label }
        end
      end
    end

    include_examples 'it renders unchecked radio'
  end

  context 'with `help_text` slot' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            value: value,
            label: label
          )
        ) do |c|
          c.with_help_text { help_text }
        end
      end
    end

    include_examples 'it renders unchecked radio'
    include_examples 'it renders help text'
  end

  context 'with `label` and `help_text` slots' do
    before do
      fake_form_for do |form|
        render_inline(
          described_class.new(
            form: form,
            method: method,
            value: value
          )
        ) do |c|
          c.with_label { label }
          c.with_help_text { help_text }
        end
      end
    end

    include_examples 'it renders unchecked radio'
    include_examples 'it renders help text'
  end
end
