class Spinach::Features::ProfileActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  step 'the active main tab should be Home' do
    ensure_active_main_tab('Profile')
  end

  step 'the active main tab should be Account' do
    ensure_active_main_tab('Account')
  end

  step 'the active main tab should be SSH Keys' do
    ensure_active_main_tab('SSH Keys')
  end

  step 'the active main tab should be Preferences' do
    ensure_active_main_tab('Preferences')
  end

  step 'the active main tab should be Audit Log' do
    ensure_active_main_tab('Audit Log')
  end
end
