class Spinach::Features::LoginForm < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedSnippet
  include SharedUser
  include SharedSearch

  step 'Crowd integration enabled' do
    @providers_orig = Gitlab::OAuth::Provider.providers
    @omniauth_conf_orig = Gitlab.config.omniauth.enabled
    expect(Gitlab::OAuth::Provider).to receive(:providers).and_return([:crowd])
    allow_any_instance_of(ApplicationHelper).to receive(:user_omniauth_authorize_path).and_return(root_path)
    expect(Gitlab.config.omniauth).to receive(:enabled).and_return(true)
  end

  step 'I should see Crowd login form' do
    expect(page).to have_selector '#tab-crowd form'
    Gitlab::OAuth::Provider.stub(:providers).and_return(@providers_orig)
    Gitlab.config.omniauth.stub(:enabled).and_return(@omniauth_conf_orig)
  end

  step 'I visit sign in page' do
    visit new_user_session_path
  end
end
