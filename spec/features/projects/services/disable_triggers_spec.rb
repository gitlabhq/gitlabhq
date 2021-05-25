# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Disable individual triggers', :js do
  include_context 'project service activation'

  let(:checkbox_selector) { 'input[name$="_events]"]' }

  before do
    visit_project_integration(service_name)
  end

  context 'service has multiple supported events' do
    let(:service_name) { 'Jenkins' }

    it 'shows trigger checkboxes' do
      event_count = Integrations::Jenkins.supported_events.count

      expect(page).to have_content "Trigger"
      expect(page).to have_css(checkbox_selector, visible: :all, count: event_count)
    end
  end

  context 'services only has one supported event' do
    let(:service_name) { 'Asana' }

    it "doesn't show unnecessary Trigger checkboxes" do
      expect(page).not_to have_content "Trigger"
      expect(page).not_to have_css(checkbox_selector, visible: :all)
    end
  end
end
