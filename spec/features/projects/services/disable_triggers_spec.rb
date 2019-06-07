require 'spec_helper'

describe 'Disable individual triggers' do
  let(:project) { create(:project) }
  let(:user) { project.owner }
  let(:checkbox_selector) { 'input[type=checkbox][id$=_events]' }

  before do
    sign_in(user)

    visit(project_settings_integrations_path(project))

    click_link(service_name)
  end

  context 'service has multiple supported events' do
    let(:service_name) { 'HipChat' }

    it 'shows trigger checkboxes' do
      event_count = HipchatService.supported_events.count

      expect(page).to have_content "Trigger"
      expect(page).to have_css(checkbox_selector, count: event_count)
    end
  end

  context 'services only has one supported event' do
    let(:service_name) { 'Asana' }

    it "doesn't show unnecessary Trigger checkboxes" do
      expect(page).not_to have_content "Trigger"
      expect(page).not_to have_css(checkbox_selector)
    end
  end
end
