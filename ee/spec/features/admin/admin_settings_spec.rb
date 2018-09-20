require 'spec_helper'

describe 'Admin updates EE-only settings' do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
    allow(License).to receive(:feature_available?).and_return(true)
  end

  it 'Modify GitLab Geo settings' do
    visit geo_admin_application_settings_path
    page.within('.as-geo') do
      fill_in 'Connection timeout', with: 15
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.geo_status_timeout).to eq(15)
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Enable external authentication' do
    visit admin_application_settings_path
    page.within('.as-external-auth') do
      check 'Enable classification control using an external service'
      fill_in 'Default classification label', with: 'default'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Enable elastic search indexing' do
    visit integrations_admin_application_settings_path
    page.within('.as-elasticsearch') do
      check 'Elasticsearch indexing'
      click_button 'Save changes'
    end

    expect(Gitlab::CurrentSettings.elasticsearch_indexing).to be_truthy
    expect(page).to have_content "Application settings saved successfully"
  end

  it 'Enable Slack application' do
    visit integrations_admin_application_settings_path
    allow(Gitlab).to receive(:com?).and_return(true)
    visit integrations_admin_application_settings_path

    page.within('.as-slack') do
      check 'Enable Slack application'
      click_button 'Save changes'
    end

    expect(page).to have_content "Application settings saved successfully"
  end

  context 'Templates page' do
    before do
      visit templates_admin_application_settings_path
    end

    it 'Render "Templates" section' do
      page.within('.as-visibility-access') do
        expect(page).to have_content "Templates"
      end
    end

    it 'Render "Custom project templates" section' do
      page.within('.as-custom-project-templates') do
        expect(page).to have_content "Custom project templates"
      end
    end
  end
end
