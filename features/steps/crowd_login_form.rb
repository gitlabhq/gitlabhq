class Spinach::Features::CrowdLoginForm < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSnippet
  include SharedUser
  include SharedSearch

  step 'Crowd integration enabled' do
    Gitlab::OAuth::Provider.should_receive(:providers).and_return([:crowd])
    allow_any_instance_of(ApplicationHelper).to receive(:user_omniauth_authorize_path).and_return(root_path)
    Gitlab.config.omniauth.should_receive(:enabled).and_return(true)
  end

  step 'I should see Crowd login form' do
    expect(page).to have_selector '#tab-crowd form'
  end

  step 'I visit sign in page' do
    visit new_user_session_path
  end
end