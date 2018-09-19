require 'spec_helper'

describe 'Admin updates EE-only settings' do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
    allow(License).to receive(:feature_available?).and_return(true)
    visit admin_application_settings_path
  end

  it 'Modify GitLab Geo settings' do
    page.within('.as-geo') do
      fill_in 'Connection timeout', with: 15
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.geo_status_timeout).to eq(15)
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Enable external authentication' do
    page.within('.as-external-auth') do
      check 'Enable classification control using an external service'
      fill_in 'Default classification label', with: 'default'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Enable elastic search indexing' do
    page.within('.as-elasticsearch') do
      check 'Elasticsearch indexing'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.elasticsearch_indexing).to be_truthy
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Enable Slack application' do
    allow(Gitlab).to receive(:com?).and_return(true)
    visit admin_application_settings_path

    page.within('.as-slack') do
      check 'Enable Slack application'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
  end
end
