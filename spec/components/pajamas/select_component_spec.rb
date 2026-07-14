# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::SelectComponent, :aggregate_failures, feature_category: :design_system do
  let(:name) { :role }
  let(:choices) { [['Guest', 10], ['Reporter', 20]] }

  context 'with default options' do
    before do
      render_inline(described_class.new(name: name, choices: choices))
    end

    it 'renders the design system select wrapper around a styled select' do
      expect(page).to have_css('.gl-form-select-wrapper > select.gl-form-select.custom-select')
    end

    it 'sets the select name' do
      expect(page).to have_css('select[name="role"]')
    end

    it 'renders the given options' do
      expect(page).to have_css('option[value="10"]', text: 'Guest')
      expect(page).to have_css('option[value="20"]', text: 'Reporter')
    end

    it 'does not overlay an icon element for the chevron' do
      # The chevron is drawn by the .gl-form-select-wrapper::after pseudo-element,
      # so there must be no overlaid icon that could intercept clicks (the 520101 bug).
      expect(page).not_to have_css('.gl-form-select-wrapper svg')
    end

    it 'does not constrain the width' do
      expect(page).to have_css('.gl-form-select-wrapper')
      expect(page).not_to have_css('.gl-form-select-wrapper.gl-form-select-md')
    end
  end

  context 'with choices given as a hash' do
    let(:choices) { { 'Guest' => 10, 'Reporter' => 20 } }

    before do
      render_inline(described_class.new(name: name, choices: choices))
    end

    it 'renders the options through options_for_select' do
      expect(page).to have_css('option[value="10"]', text: 'Guest')
      expect(page).to have_css('option[value="20"]', text: 'Reporter')
    end
  end

  context 'with a selected value' do
    before do
      render_inline(described_class.new(name: name, choices: choices, selected: 20))
    end

    it 'marks the matching option as selected' do
      expect(page).to have_css('option[value="20"][selected]')
      expect(page).not_to have_css('option[value="10"][selected]')
    end
  end

  context 'with a width' do
    before do
      render_inline(described_class.new(name: name, choices: choices, width: :md))
    end

    it 'adds the width modifier to the wrapper' do
      expect(page).to have_css('.gl-form-select-wrapper.gl-form-select-md')
    end
  end

  context 'with an invalid width' do
    before do
      render_inline(described_class.new(name: name, choices: choices, width: :enormous))
    end

    it 'ignores it' do
      expect(page).to have_css('.gl-form-select-wrapper')
      expect(page).not_to have_css('.gl-form-select-enormous')
    end
  end

  context 'with custom select and wrapper options' do
    before do
      render_inline(
        described_class.new(
          name: name,
          choices: choices,
          select_options: { class: 'js-foo', data: { testid: 'role-select' } },
          wrapper_options: { class: 'wrapper-foo' }
        )
      )
    end

    it 'merges custom classes and attributes without dropping the component classes' do
      expect(page).to have_css('.gl-form-select-wrapper.wrapper-foo')
      expect(page).to have_css('select.gl-form-select.custom-select.js-foo[data-testid="role-select"]')
    end
  end
end
