# frozen_string_literal: true

require "spec_helper"

RSpec.describe Layouts::SettingsBlockComponent, type: :component, feature_category: :shared do
  let(:heading) { 'Settings block heading' }
  let(:description) { 'Settings block description' }
  let(:body) { 'Settings block content' }
  let(:id) { 'js-settings-block-id' }
  let(:testid) { 'settings-block-testid' }

  describe 'slots' do
    it 'renders heading' do
      render_inline described_class.new(heading)

      expect(page).to have_css('h2.gl-heading-2', text: heading)
    end

    it 'renders description' do
      render_inline described_class.new(heading, description: description)

      expect(page).to have_css('.gl-text-subtle', text: description)
    end

    it 'renders description slot' do
      render_inline described_class.new(heading) do |c|
        c.with_description { description }
      end

      expect(page).to have_css('.gl-text-subtle', text: description)
    end

    it 'renders body slot' do
      render_inline described_class.new(heading) do |c|
        c.with_body { body }
      end

      expect(page).to have_css('.settings-content', text: body)
    end

    it 'renders id' do
      render_inline described_class.new(heading, id: id)

      expect(page).to have_css('#js-settings-block-id')
    end

    it 'renders testid' do
      render_inline described_class.new(heading, testid: testid)

      expect(page).to have_css('[data-testid="settings-block-testid"]')
    end

    it 'renders collapsed if not expanded' do
      render_inline described_class.new(heading, expanded: nil)

      # expect(page).to have_css('.js-settings-toggle', text: 'Expand')
      expect(page).to have_selector('.settings-toggle[aria-label^="Expand"]')
    end

    it 'renders expanded if expanded' do
      render_inline described_class.new(heading, expanded: true)

      expect(page).to have_css('.settings.expanded')
      # expect(page).to have_css('.js-settings-toggle', text: 'Collapse')
      expect(page).to have_selector('.settings-toggle[aria-label^="Collapse"]')
    end
  end
end
