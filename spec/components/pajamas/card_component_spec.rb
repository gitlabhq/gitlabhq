# frozen_string_literal: true

require "spec_helper"

RSpec.describe Pajamas::CardComponent, :aggregate_failures, type: :component, feature_category: :design_system do
  let(:header) { 'Slot header' }
  let(:body) { 'Slot body' }
  let(:footer) { 'Slot footer' }

  context 'for slots' do
    let(:card) { {} }

    before do
      render_inline described_class.new(card: card) do |c|
        c.with_header { header }
        c.with_body { body }
        c.with_footer { footer }
      end
    end

    it 'renders card header' do
      expect(page).to have_content(header)
    end

    it 'renders card body' do
      expect(page).to have_content(body)
    end

    it 'renders footer' do
      expect(page).to have_content(footer)
    end

    context 'when both slots and card is supplied slot will override' do
      let(:card) { { header: 'Card header', body: 'Card body', footer: 'Card footer' } }

      it 'renders card header' do
        expect(page).to have_content(header)
        expect(page).not_to have_content(card[:header])
      end

      it 'renders card body' do
        expect(page).to have_content(body)
        expect(page).not_to have_content(card[:body])
      end

      it 'renders footer' do
        expect(page).to have_content(footer)
        expect(page).not_to have_content(card[:footer])
      end
    end
  end

  context 'with defaults' do
    before do
      render_inline described_class.new
    end

    it 'does not have a header or footer' do
      expect(page).not_to have_selector('.gl-card-header')
      expect(page).not_to have_selector('.gl-card-footer')
    end

    it 'renders the card and body' do
      expect(page).to have_selector('.gl-card')
      expect(page).to have_selector('.gl-card-body')
    end
  end

  context 'with custom options' do
    before do
      render_inline described_class.new(
        card_options: { class: '_card_class_', data: { testid: '_card_testid_' } },
        header_options: { class: '_header_class_', data: { testid: '_header_testid_' } },
        body_options: { class: '_body_class_', data: { testid: '_body_testid_' } },
        footer_options: { class: '_footer_class_', data: { testid: '_footer_testid_' } }) do |c|
        c.with_header { header }
        c.with_body { body }
        c.with_footer { footer }
      end
    end

    it 'renders card options' do
      expect(page).to have_selector('._card_class_')
      expect(page).to have_selector('[data-testid="_card_testid_"]')
    end

    it 'renders header options' do
      expect(page).to have_selector('._header_class_')
      expect(page).to have_selector('[data-testid="_header_testid_"]')
    end

    it 'renders body options' do
      expect(page).to have_selector('._body_class_')
      expect(page).to have_selector('[data-testid="_body_testid_"]')
    end

    it 'renders footer options' do
      expect(page).to have_selector('._footer_class_')
      expect(page).to have_selector('[data-testid="_footer_testid_"]')
    end
  end

  context 'with collection' do
    let(:first_card) { { header: 'First card header', body: 'Card body', footer: 'Card footer' } }
    let(:second_card) { { body: 'Second card body' } }

    before do
      render_inline described_class.with_collection([first_card, second_card])
    end

    it 'renders 2 cards' do
      expect(page).to have_selector('.gl-card', count: 2)
    end

    it 'renders all elements for first card' do
      expect(page).to have_content(first_card[:header])
      expect(page).to have_content(first_card[:body])
      expect(page).to have_content(first_card[:footer])
    end

    it 'renders only body for second card' do
      expect(page).to have_selector('.gl-card-header', count: 1)
      expect(page).to have_content(second_card[:body])
      expect(page).to have_selector('.gl-card-footer', count: 1)
    end
  end
end
