# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Disable individual triggers', :js, feature_category: :integrations do
  include_context 'project integration activation'

  let(:checkbox_selector) { 'input[name$="_events]"]' }

  before do
    visit_project_integration(integration_name)
  end

  context 'integration has multiple supported events' do
    let(:integration_name) { 'Jenkins' }

    it 'shows trigger checkboxes' do
      event_count = Integrations::Jenkins.supported_events.count

      expect(page).to have_content "Trigger"
      expect(page).to have_css(checkbox_selector, visible: :all, count: event_count)
    end
  end

  context 'integrations only has one supported event' do
    let(:integration_name) { 'Asana' }

    it "doesn't show unnecessary Trigger checkboxes" do
      expect(page).not_to have_content "Trigger"
      expect(page).not_to have_css(checkbox_selector, visible: :all)
    end
  end
end
