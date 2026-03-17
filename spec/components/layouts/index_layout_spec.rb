# frozen_string_literal: true

require "spec_helper"

RSpec.describe Layouts::IndexLayout, feature_category: :design_system do
  let(:heading) { 'Page heading' }
  let(:description) { 'Page description' }
  let(:alerts_content) { 'Alert message' }
  let(:content) { 'Default content' }

  it 'renders with heading and description props' do
    render_inline described_class.new(heading: heading, description: description)

    expect(page).to have_css('h1.gl-heading-1', text: heading)
    expect(page).to have_css('.gl-text-subtle', text: description)
  end

  it 'renders alerts and content slots' do
    render_inline described_class.new(heading: heading) do |c|
      c.with_alerts { alerts_content }
      content
    end

    expect(page).to have_css('[data-testid="index-layout-alerts"]', text: alerts_content)
    expect(page).to have_css('[data-testid="index-layout-content"]', text: content)
  end

  it 'does not render alerts section when empty' do
    render_inline described_class.new(heading: heading) do
      content
    end

    expect(page).not_to have_css('[data-testid="index-layout-alerts"]')
  end
end
