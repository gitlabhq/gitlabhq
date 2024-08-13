# frozen_string_literal: true

require "spec_helper"

RSpec.describe Layouts::SettingsSectionComponent, type: :component, feature_category: :shared do
  let(:heading) { 'Settings section heading' }
  let(:description) { 'Settings section description' }
  let(:body) { 'Settings section content' }
  let(:id) { 'js-settings-section-id' }
  let(:testid) { 'settings-section-testid' }

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

      expect(page).to have_css('[data-testid="settings-section-body"]', text: body)
    end

    it 'renders id' do
      render_inline described_class.new(heading, id: id)

      expect(page).to have_css('#js-settings-section-id')
    end

    it 'renders testid' do
      render_inline described_class.new(heading, testid: testid)

      expect(page).to have_css('[data-testid="settings-section-testid"]')
    end
  end
end
