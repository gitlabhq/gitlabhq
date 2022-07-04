# frozen_string_literal: true
require "spec_helper"

RSpec.describe Pajamas::ToggleComponent, type: :component do
  context 'with defaults' do
    before do
      render_inline described_class.new(classes: 'js-feature-toggle')
    end

    it 'renders a toggle container with provided class' do
      expect(page).to have_selector "[class='js-feature-toggle']"
    end

    it 'does not set a name' do
      expect(page).not_to have_selector('[data-name]')
    end

    it 'sets default is-checked attributes' do
      expect(page).to have_selector('[data-is-checked="false"]')
    end

    it 'sets default disabled attributes' do
      expect(page).to have_selector('[data-disabled="false"]')
    end

    it 'sets default is-loading attributes' do
      expect(page).to have_selector('[data-is-loading="false"]')
    end

    it 'does not set a label' do
      expect(page).not_to have_selector('[data-label]')
    end

    it 'does not set a label position' do
      expect(page).not_to have_selector('[data-label-position]')
    end
  end

  context 'with custom options' do
    before do
      render_inline described_class.new(
        classes: 'js-custom-gl-toggle',
        name: 'toggle-name',
        is_checked: true,
        is_disabled: true,
        is_loading: true,
        label: 'Custom label',
        label_position: :top,
        data: {
          foo: 'bar'
        })
    end

    it 'sets the custom class' do
      expect(page).to have_selector('.js-custom-gl-toggle')
    end

    it 'sets the custom name' do
      expect(page).to have_selector('[data-name="toggle-name"]')
    end

    it 'sets the custom is-checked attributes' do
      expect(page).to have_selector('[data-is-checked="true"]')
    end

    it 'sets the custom disabled attributes' do
      expect(page).to have_selector('[data-disabled="true"]')
    end

    it 'sets the custom is-loading attributes' do
      expect(page).to have_selector('[data-is-loading="true"]')
    end

    it 'sets the custom label' do
      expect(page).to have_selector('[data-label="Custom label"]')
    end

    it 'sets the custom label position' do
      expect(page).to have_selector('[data-label-position="top"]')
    end

    it 'sets custom data attributes' do
      expect(page).to have_selector('[data-foo="bar"]')
    end
  end

  context 'with setting label_position' do
    using RSpec::Parameterized::TableSyntax

    where(:position, :count) do
      :top        | 1
      :left       | 1
      :hidden     | 1
      :bogus      | 0
      'bogus'     | 0
      nil         | 0
    end

    before do
      render_inline described_class.new(classes: '_class_', label_position: position)
    end

    with_them do
      it { expect(page).to have_selector("[data-label-position='#{position}']", count: count) }
    end
  end
end
