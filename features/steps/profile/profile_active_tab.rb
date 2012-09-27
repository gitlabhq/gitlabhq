class ProfileActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  Then 'the active main tab should be Home' do
    ensure_active_main_tab('Profile')
  end

  Then 'the active main tab should be Account' do
    ensure_active_main_tab('Account')
  end

  Then 'the active main tab should be SSH Keys' do
    ensure_active_main_tab('SSH Keys')
  end

  Then 'the active main tab should be Design' do
    ensure_active_main_tab('Design')
  end

  Then 'the active main tab should be History' do
    ensure_active_main_tab('History')
  end
end
