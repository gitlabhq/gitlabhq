# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::RadioTagComponent, :aggregate_failures, type: :component, feature_category: :design_system do
  let_it_be(:name) { :access_level }
  let_it_be(:label) { "Access Level" }
  let_it_be(:value) { :regular }
  let_it_be(:help_text) do
    'Administrators have access to all groups, projects, and users and can manage all features in this installation'
  end

  shared_examples 'it renders unchecked radio' do
    it 'renders unchecked radio' do
      expect(page).to have_unchecked_field(label)
    end
  end

  shared_examples 'it renders label text' do
    it 'renders label text' do
      expect(page).to have_text(label)
    end
  end

  context 'with default options' do
    before do
      render_inline(
        described_class.new(
          name: name,
          value: value,
          label: label
        )
      )
    end

    include_examples 'it renders unchecked radio'
    include_examples 'it renders label text'
    include_examples 'it does not render help text'

    it 'renders correct label "for" attribute' do
      expect(page).to have_selector("label[for=\"#{name}_#{value}\"]")
    end
  end

  context 'with custom options' do
    let_it_be(:radio_options) { { class: 'radio-foo-bar' } }
    let_it_be(:label_options) { { class: 'label-foo-bar' } }
    let_it_be(:label) { 'Custom label' }

    before do
      render_inline(
        described_class.new(
          name: name,
          value: value,
          label: label,
          checked: true,
          help_text: help_text,
          radio_options: radio_options,
          label_options: label_options
        )
      )
    end

    include_examples 'it renders label text'
    include_examples 'it renders help text'

    it 'renders checked radio' do
      expect(page).to have_checked_field(label, class: radio_options[:class])
    end

    it 'adds CSS class to label' do
      expect(page).to have_selector('label.label-foo-bar')
    end
  end

  context 'with `label` slot' do
    let_it_be(:label) { 'Slot label' }

    before do
      render_inline(
        described_class.new(
          name: name,
          value: value
        )
      ) do |c|
        c.with_label { label }
      end
    end

    include_examples 'it renders unchecked radio'
    include_examples 'it renders label text'
  end

  context 'with `help_text` slot' do
    before do
      render_inline(
        described_class.new(
          name: name,
          value: value,
          label: label
        )
      ) do |c|
        c.with_help_text { help_text }
      end
    end

    include_examples 'it renders unchecked radio'
    include_examples 'it renders help text'
  end

  context 'with `label` and `help_text` slots' do
    let_it_be(:label) { 'Slot label' }

    before do
      render_inline(
        described_class.new(
          name: name,
          value: value
        )
      ) do |c|
        c.with_label { label }
        c.with_help_text { help_text }
      end
    end

    include_examples 'it renders unchecked radio'
    include_examples 'it renders label text'
    include_examples 'it renders help text'
  end
end
