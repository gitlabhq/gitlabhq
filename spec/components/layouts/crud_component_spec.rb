# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Layouts::CrudComponent, type: :component, feature_category: :shared do
  let(:title) { 'Title' }
  let(:description) { 'Description' }
  let(:count) { 99 }
  let(:icon) { 'rocket' }
  let(:toggle_text) { 'Toggle text' }
  let(:actions) { 'Actions' }
  let(:body) { 'Body' }
  let(:form) { 'Form' }
  let(:footer) { 'Footer' }
  let(:pagination) { 'Pagination' }
  let(:component_title) { described_class.new(title) }

  describe 'slots' do
    it 'renders title' do
      render_inline component_title

      expect(page).to have_css('[data-testid="crud-title"]', text: title)
    end

    it 'renders description' do
      render_inline described_class.new(title, description: description)

      expect(page).to have_css('[data-testid="crud-description"]', text: description)
    end

    it 'renders description slot' do
      render_inline component_title do |c|
        c.with_description { description }
      end

      expect(page).to have_css('[data-testid="crud-description"]', text: description)
    end

    it 'renders count and icon' do
      render_inline described_class.new(title, count: count, icon: icon)

      expect(page).to have_css('[data-testid="crud-count"]', text: count)
      expect(page).to have_css('[data-testid="crud-count"] svg[data-testid="rocket-icon"]')
    end

    it 'renders action toggle' do
      render_inline described_class.new(title, toggle_text: toggle_text)

      expect(page).to have_css('[data-testid="crud-action-toggle"]', text: toggle_text)
      expect(page).to have_css('.crud.js-toggle-container')
      expect(page).to have_css('[data-testid="crud-action-toggle"].js-toggle-button.js-toggle-content')
    end

    it 'renders actions slot' do
      render_inline component_title do |c|
        c.with_actions { actions }
      end

      expect(page).to have_css('[data-testid="crud-actions"]', text: actions)
    end

    it 'renders form slot' do
      render_inline component_title do |c|
        c.with_form { form }
      end

      expect(page).to have_css('[data-testid="crud-form"]', text: form)
    end

    it 'renders body slot' do
      render_inline component_title do |c|
        c.with_body { body }
      end

      expect(page).to have_css('[data-testid="crud-body"]', text: body)
    end

    it 'renders footer slot' do
      render_inline component_title do |c|
        c.with_footer { footer }
      end

      expect(page).to have_css('[data-testid="crud-footer"]', text: footer)
    end

    it 'renders pagination slot' do
      render_inline component_title do |c|
        c.with_pagination { pagination }
      end

      expect(page).to have_css('[data-testid="crud-pagination"]', text: pagination)
    end
  end
end
