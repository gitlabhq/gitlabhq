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
end
