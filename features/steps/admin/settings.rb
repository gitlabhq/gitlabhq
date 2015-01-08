class Spinach::Features::AdminSettings < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedAdmin
  include Gitlab::CurrentSettings

  step 'I disable gravatars and save form' do
    uncheck 'Gravatar enabled'
    click_button 'Save'
  end

  step 'I should be see gravatar disabled' do
    current_application_settings.gravatar_enabled.should be_false
    page.should have_content 'Application settings saved successfully'
  end
end
