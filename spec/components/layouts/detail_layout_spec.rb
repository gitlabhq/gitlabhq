# frozen_string_literal: true

require "spec_helper"

RSpec.describe Layouts::DetailLayout, feature_category: :design_system do
  let(:heading) { 'Page heading' }
  let(:sidebar) { 'Sidebar' }
  let(:content) { 'Default content' }

  it_behaves_like 'a base layout component'

  describe 'slots' do
    describe 'sidebar' do
      it 'renders sidebar content when slot is provided' do
        render_inline described_class.new(heading: heading) do |c|
          c.with_sidebar { sidebar }
          content
        end

        expect(page).to have_css('[data-testid="detail-layout-sidebar"]', text: sidebar)
      end
    end

    describe 'widgets' do
      let(:widgets) { 'Widgets' }

      it 'renders widgets content when slot is provided' do
        render_inline described_class.new(heading: heading) do |c|
          c.with_widgets { widgets }
          content
        end

        expect(page).to have_css('[data-testid="detail-layout-widgets"]', text: widgets)
      end

      it 'does not render when no widgets slot is provided' do
        render_inline described_class.new(heading: heading) { content }

        expect(page).not_to have_css('[data-testid="detail-layout-widgets"]')
      end
    end

    describe 'activity' do
      let(:activity) { 'Activity' }

      it 'renders activity content when slot is provided' do
        render_inline described_class.new(heading: heading) do |c|
          c.with_activity { activity }
          content
        end

        expect(page).to have_css('[data-testid="detail-layout-activity"]', text: activity)
      end

      it 'does not render when no activity slot is provided' do
        render_inline described_class.new(heading: heading) { content }

        expect(page).not_to have_css('[data-testid="detail-layout-activity"]')
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
