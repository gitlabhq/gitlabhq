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

    it 'renders icon class' do
      render_inline described_class.new(title, count: count, icon: icon, icon_class: 'test-icon-class')

      expect(page).to have_css('[data-testid="crud-count"] svg[data-testid="rocket-icon"].test-icon-class')
    end

    it 'renders action toggle' do
      render_inline described_class.new(title, toggle_text: toggle_text)

      expect(page).to have_css('[data-testid="crud-action-toggle"]', text: toggle_text)
      expect(page).to have_css('.crud.js-toggle-container')
      expect(page).to have_css('[data-testid="crud-action-toggle"].js-toggle-button.js-toggle-content')
    end

    it 'renders action toggle custom attributes' do
      render_inline described_class.new(title,
        toggle_text: toggle_text,
        toggle_options: { class: 'custom-button-class', data: { testid: 'crud-custom-toggle-id' } })

      expect(page).to have_css('.custom-button-class', text: toggle_text)
      expect(page).to have_css('[data-testid="crud-custom-toggle-id"]', text: toggle_text)
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

    it 'renders hidden form slot if toggle is set' do
      render_inline described_class.new(title, toggle_text: toggle_text) do |c|
        c.with_form { form }
      end

      expect(page).to have_css('.gl-hidden', text: form)
      expect(page).to have_css('[data-testid="crud-form"].js-toggle-content', text: form)
    end

    it 'renders form visible when form has errors and toggle_text is present' do
      render_inline described_class.new(title,
        toggle_text: toggle_text,
        form_options: { form_errors: true }) do |c|
        c.with_form { form }
      end

      expect(page).not_to have_css('.gl-hidden', text: form)
    end

    it 'renders form custom attributes' do
      render_inline described_class.new(title,
        form_options: { class: 'form-class', data: { testid: 'crud-custom-form-id' } }) do |c|
        c.with_form { form }
      end

      expect(page).to have_css('.form-class', text: form)
      expect(page).to have_css('[data-testid="crud-custom-form-id"]', text: form)
    end

    it 'renders body slot' do
      render_inline component_title do |c|
        c.with_body { body }
      end

      expect(page).to have_css('[data-testid="crud-body"]', text: body)
    end

    it 'renders body custom attributes' do
      render_inline described_class.new(title,
        body_options: { class: '!gl-m-0', data: { testid: 'crud-custom-body-id' } }) do |c|
        c.with_body { body }
      end

      expect(page).to have_css('.\!gl-m-0', text: body)
      expect(page).to have_css('[data-testid="crud-custom-body-id"]', text: body)
    end

    it 'renders footer slot' do
      render_inline component_title do |c|
        c.with_footer { footer }
      end

      expect(page).to have_css('[data-testid="crud-footer"]', text: footer)
    end

    it 'renders footer custom attributes' do
      render_inline described_class.new(title,
        footer_options: { class: 'footer-class', data: { testid: 'crud-custom-footer-id' } }) do |c|
        c.with_footer { footer }
      end

      expect(page).to have_css('.footer-class', text: footer)
      expect(page).to have_css('[data-testid="crud-custom-footer-id"]', text: footer)
    end

    it 'renders pagination slot' do
      render_inline component_title do |c|
        c.with_pagination { pagination }
      end

      expect(page).to have_css('[data-testid="crud-pagination"]', text: pagination)
    end
  end

  describe 'collapsible functionality' do
    it 'renders collapse/expand button when is_collapsible is true' do
      render_inline described_class.new(title, is_collapsible: true)

      expect(page).to have_css('.js-crud-collapsible-button', text: '')
      expect(page).to have_css('.js-crud-collapsible-button[aria-expanded="true"]')
      expect(page).to have_css('.js-crud-collapsible-button[aria-controls]')
      expect(page).to have_css('.js-crud-collapsible-button[title="Collapse"]')
      expect(page).to have_css('.js-crud-collapsible-button[data-collapse-title="Expand"]')
      expect(page).to have_css('.js-crud-collapsible-button[data-expand-title="Collapse"]')
      expect(page).to have_css('.js-crud-collapsible-collapse')
      expect(page).to have_css('.js-crud-collapsible-expand.gl-hidden')
    end
  end
end
