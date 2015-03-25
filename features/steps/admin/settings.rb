class Spinach::Features::AdminSettings < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin
  include Gitlab::CurrentSettings

  step 'I modify settings and save form' do
    uncheck 'Gravatar enabled'
    fill_in 'Home page url', with: 'https://about.gitlab.com/'
    click_button 'Save'
  end

  step 'I should see application settings saved' do
    current_application_settings.gravatar_enabled.should be_false
    current_application_settings.home_page_url.should == 'https://about.gitlab.com/'
    page.should have_content 'Application settings saved successfully'
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
    fill_in 'Webhook', with: "http://localhost"
    click_on 'Save'
  end

  step 'I should see service template settings saved' do
    page.should have_content 'Application settings saved successfully'
  end

  step 'I should see all checkboxes checked' do
    all('input[type=checkbox]').each do |checkbox|
      checkbox.should be_checked
    end
  end
end
