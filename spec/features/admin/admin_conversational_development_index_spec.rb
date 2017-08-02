require 'spec_helper'

describe 'Admin Conversational Development Index' do
  before do
    sign_in(create(:admin))
  end

  context 'when usage ping is disabled' do
    it 'shows empty state' do
      stub_application_setting(usage_ping_enabled: false)

      visit admin_conversational_development_index_path

      expect(page).to have_content('Usage ping is not enabled')
    end
  end

  context 'when there is no data to display' do
    it 'shows empty state' do
      stub_application_setting(usage_ping_enabled: true)

      visit admin_conversational_development_index_path

      expect(page).to have_content('Data is still calculating')
    end
  end

  context 'when there is data to display' do
    it 'shows numbers for each metric' do
      stub_application_setting(usage_ping_enabled: true)
      create(:conversational_development_index_metric)

      visit admin_conversational_development_index_path

      expect(page).to have_content(
        'Issues created per active user 1.2 You 9.3 Lead 13.3%'
      )
    end
  end
end
