require 'spec_helper'

feature 'Admin updates settings', feature: true do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
    sign_in(create(:admin))
    visit admin_application_settings_path
  end

  scenario 'Change visibility settings' do
    choose "application_setting_default_project_visibility_20"
    click_button 'Save'

    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Uncheck all restricted visibility levels' do
    find('#application_setting_visibility_level_0').set(false)
    find('#application_setting_visibility_level_10').set(false)
    find('#application_setting_visibility_level_20').set(false)

    click_button 'Save'

    expect(page).to have_content "Application settings saved successfully"
    expect(find('#application_setting_visibility_level_0')).not_to be_checked
    expect(find('#application_setting_visibility_level_10')).not_to be_checked
    expect(find('#application_setting_visibility_level_20')).not_to be_checked
  end

  scenario 'Change application settings' do
    uncheck 'Gravatar enabled'
    fill_in 'Home page URL', with: 'https://about.gitlab.com/'
    fill_in 'Help page text', with: 'Example text'
    check 'Hide marketing-related entries from help'
    fill_in 'Support page URL', with: 'http://example.com/help'
    click_button 'Save'

    expect(current_application_settings.gravatar_enabled).to be_falsey
    expect(current_application_settings.home_page_url).to eq "https://about.gitlab.com/"
    expect(current_application_settings.help_page_text).to eq "Example text"
    expect(current_application_settings.help_page_hide_commercial_content).to be_truthy
    expect(current_application_settings.help_page_support_url).to eq "http://example.com/help"
    expect(page).to have_content "Application settings saved successfully"
  end

  scenario 'Change Slack Notifications Service template settings' do
    click_link 'Service Templates'
    click_link 'Slack notifications'
    fill_in 'Webhook', with: 'http://localhost'
    fill_in 'Username', with: 'test_user'
    fill_in 'service_push_channel', with: '#test_channel'
    page.check('Notify only broken pipelines')
    page.check('Notify only default branch')

    check_all_events
    click_on 'Save'

    expect(page).to have_content 'Application settings saved successfully'

    click_link 'Slack notifications'

    page.all('input[type=checkbox]').each do |checkbox|
      expect(checkbox).to be_checked
    end
    expect(find_field('Webhook').value).to eq 'http://localhost'
    expect(find_field('Username').value).to eq 'test_user'
    expect(find('#service_push_channel').value).to eq '#test_channel'
  end

  def check_all_events
    page.check('Active')
    page.check('Push')
    page.check('Tag push')
    page.check('Note')
    page.check('Issue')
    page.check('Merge request')
    page.check('Pipeline')
  end
end
