require 'rails_helper'

describe 'Cohorts page', :js do
  before do
    sign_in(create(:admin))
  end

  it 'hides cohorts nav button when usage ping is disabled' do
    stub_application_setting(usage_ping_enabled: false)

    visit instance_statistics_root_path

    expect(find('.nav-sidebar')).not_to have_content('Cohorts')
  end

  it 'shows cohorts nav button when usage ping is enabled' do
    stub_application_setting(usage_ping_enabled: true)

    visit instance_statistics_root_path

    expect(find('.nav-sidebar')).to have_content('Cohorts')
  end
end
