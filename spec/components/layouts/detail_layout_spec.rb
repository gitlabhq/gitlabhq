# frozen_string_literal: true

require "spec_helper"

RSpec.describe Layouts::DetailLayout, feature_category: :design_system do
  let(:heading) { 'Page heading' }
  let(:description) { 'Page description' }
  let(:alerts_content) { 'Alert message' }
  let(:sidebar) { 'Sidebar' }
  let(:content) { 'Default content' }

  describe 'PageHeading' do
    describe 'heading' do
      it 'renders when heading prop is provided' do
        render_inline described_class.new(heading: heading)

        expect(page).to have_css('[data-testid="page-heading"]', text: heading)
      end

      it 'renders when heading slot is provided' do
        render_inline described_class.new do |c|
          c.with_heading { 'Custom Heading' }
        end

        expect(page).to have_css('[data-testid="page-heading"]', text: 'Custom Heading')
      end
    end

    describe 'description' do
      it 'renders description when prop provided' do
        render_inline described_class.new(heading: heading, description: description)

        expect(page).to have_css('[data-testid="page-heading-description"]', text: description)
      end

      it 'renders description when slot provided' do
        render_inline described_class.new(heading: heading) do |c|
          c.with_description { 'Test description' }
        end

        expect(page).to have_css('[data-testid="page-heading-description"]', text: 'Test description')
      end

      it 'does not render when no description prop or slot is provided' do
        render_inline described_class.new(heading: heading)

        expect(page).not_to have_css('[data-testid="page-heading-description"]')
      end
    end

    describe 'actions' do
      it 'renders actions when slot provided' do
        render_inline described_class.new(heading: heading) do |c|
          c.with_actions { 'Test action' }
        end

        expect(page).to have_css('[data-testid="page-heading-actions"]', text: 'Test action')
      end

      it 'does not render when no actions slot is provided' do
        render_inline described_class.new(heading: heading)

        expect(page).not_to have_css('[data-testid="page-heading-actions"]')
      end
    end
  end

  describe 'page_heading_sr_only' do
    it 'does not apply gl-sr-only class by default' do
      render_inline described_class.new(heading: heading)
      expect(page).not_to have_css('.gl-sr-only')
    end

    it 'applies gl-sr-only class when page_heading_sr_only is true' do
      render_inline described_class.new(heading: heading, page_heading_sr_only: true)
      expect(page).to have_css('.gl-sr-only')
    end
  end

  describe 'loading' do
    it 'renders spinner component when loading is true' do
      render_inline described_class.new(heading: heading, loading: true) do
        content
      end

      expect(page).to have_css('[data-testid="detail-layout-loading-icon"]')
    end

    it 'does not render spinner component when loading is false' do
      render_inline described_class.new(heading: heading, loading: false) do
        content
      end

      expect(page).not_to have_css('[data-testid="detail-layout-loading-icon"]')
    end

    it 'does not render container, content, or sidebar when loading' do
      render_inline described_class.new(heading: heading, loading: true) do |c|
        c.with_sidebar { sidebar }
        content
      end

      expect(page).not_to have_css('[data-testid="detail-layout-container"]')
      expect(page).not_to have_css('[data-testid="detail-layout-content"]', text: content)
      expect(page).not_to have_css('[data-testid="detail-layout-sidebar"]', text: sidebar)
    end

    it 'renders container, content, and sidebar when not loading' do
      render_inline described_class.new(heading: heading, loading: false) do |c|
        c.with_sidebar { sidebar }
        content
      end

      expect(page).to have_css('[data-testid="detail-layout-container"]')
      expect(page).to have_css('[data-testid="detail-layout-content"]', text: content)
      expect(page).to have_css('[data-testid="detail-layout-sidebar"]', text: sidebar)
    end
  end

  describe 'slots' do
    describe 'alerts' do
      it 'renders alert content when slot is provided' do
        render_inline described_class.new(heading: heading) do |c|
          c.with_alerts { alerts_content }
        end

        expect(page).to have_css('[data-testid="detail-layout-alerts"]', text: alerts_content)
      end

      it 'does not render when no alerts slot is provided' do
        render_inline described_class.new(heading: heading)

        expect(page).not_to have_css('[data-testid="detail-layout-alerts"]')
      end
    end

    describe 'sidebar' do
      it 'renders sidebar content when slot is provided' do
        render_inline described_class.new(heading: heading) do |c|
          c.with_sidebar { sidebar }
          content
        end

        expect(page).to have_css('[data-testid="detail-layout-sidebar"]', text: sidebar)
      end
    end

    describe 'default' do
      it 'renders body when default slot is provided' do
        render_inline described_class.new(heading: heading) do
          content
        end

        expect(page).to have_css('[data-testid="detail-layout-content"]', text: content)
      end
    end
  end
end
