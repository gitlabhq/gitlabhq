class Spinach::Features::AdminSettings < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin
  include Gitlab::CurrentSettings

  step 'I modify settings and save form' do
    uncheck 'Gravatar enabled'
    fill_in 'Home page URL', with: 'https://about.gitlab.com/'
    fill_in 'Help page text', with: 'Example text'
    click_button 'Save'
  end

  step 'I should see application settings saved' do
    expect(current_application_settings.gravatar_enabled).to be_falsey
    expect(current_application_settings.home_page_url).to eq "https://about.gitlab.com/"
    expect(page).to have_content "Application settings saved successfully"
  end

  step 'I click on "Service Templates"' do
    click_link 'Service Templates'
  end

  step 'I click on "Slack" service' do
    click_link 'Slack'
  end

  step 'I check all events and submit form' do
    page.check('Active')
    page.check('Push events')
    page.check('Tag push events')
    page.check('Comments')
    page.check('Issues events')
    page.check('Merge Request events')
    page.check('Build events')
    click_on 'Save'
  end

  step 'I fill out Slack settings' do
    fill_in 'Webhook', with: 'http://localhost'
    fill_in 'Username', with: 'test_user'
    fill_in 'Channel', with: '#test_channel'
    page.check('Notify only broken builds')
  end

  step 'I should see service template settings saved' do
    expect(page).to have_content 'Application settings saved successfully'
  end

  step 'I should see all checkboxes checked' do
    page.all('input[type=checkbox]').each do |checkbox|
      expect(checkbox).to be_checked
    end
  end

  step 'I should see Slack settings saved' do
    expect(find_field('Webhook').value).to eq 'http://localhost'
    expect(find_field('Username').value).to eq 'test_user'
    expect(find_field('Channel').value).to eq '#test_channel'
  end
end
