class Spinach::Features::LoginForm < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSnippet
  include SharedUser
  include SharedSearch

  step 'Sign-in is disabled' do
    allow_any_instance_of(ApplicationHelper).to receive(:signin_enabled?).and_return(false)
  end

  step 'Crowd integration enabled' do
    expect(Gitlab::OAuth::Provider).to receive(:providers).and_return([:crowd])
    expect(Gitlab.config.omniauth).to receive(:enabled).and_return(true)
    allow_any_instance_of(ApplicationHelper).to receive(:user_omniauth_authorize_path).and_return(root_path)
  end

  step 'I should see Crowd login form' do
    expect(page).to have_selector '#tab-crowd form'
  end

  step 'I visit sign in page' do
    visit new_user_session_path
  end
end
