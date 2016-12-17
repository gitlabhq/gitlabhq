require 'spec_helper'

feature 'Admin updates settings', feature: true do
  before(:each) do
    login_as :admin
    visit admin_application_settings_path
  end

  scenario 'Change application settings' do
    uncheck 'Gravatar enabled'
    fill_in 'Home page URL', with: 'https://about.gitlab.com/'
    fill_in 'Help page text', with: 'Example text'
    click_button 'Save'

    expect(current_application_settings.gravatar_enabled).to be_falsey
    expect(current_application_settings.home_page_url).to eq "https://about.gitlab.com/"
    expect(page).to have_content "Application settings saved successfully"
  end

<<<<<<< HEAD:features/steps/admin/settings.rb
  step 'I set the help text' do
    fill_in 'Help text', with: help_text
    click_button 'Save'
  end

  step 'I should see the help text' do
    expect(page).to have_content help_text
  end

  step 'I go to help page' do
    visit '/help'
  end

  step 'I click on "Service Templates"' do
=======
  scenario 'Change Slack Service template settings' do
>>>>>>> ce/master:spec/features/admin/admin_settings_spec.rb
    click_link 'Service Templates'
    click_link 'Slack'
    fill_in 'Webhook', with: 'http://localhost'
    fill_in 'Username', with: 'test_user'
    fill_in 'service_push_channel', with: '#test_channel'
    page.check('Notify only broken builds')

    check_all_events
    click_on 'Save'

    expect(page).to have_content 'Application settings saved successfully'

    click_link 'Slack'

    page.all('input[type=checkbox]').each do |checkbox|
      expect(checkbox).to be_checked
    end
    expect(find_field('Webhook').value).to eq 'http://localhost'
    expect(find_field('Username').value).to eq 'test_user'
    expect(find('#service_push_channel').value).to eq '#test_channel'
  end

<<<<<<< HEAD:features/steps/admin/settings.rb
  def help_text
    'For help related to GitLab contact Marc Smith at marc@smith.example or find him in office 42.'
=======
  def check_all_events
    page.check('Active')
    page.check('Push')
    page.check('Tag push')
    page.check('Note')
    page.check('Issue')
    page.check('Merge request')
    page.check('Build')
    page.check('Pipeline')
>>>>>>> ce/master:spec/features/admin/admin_settings_spec.rb
  end
end
