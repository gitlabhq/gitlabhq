class AdminActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  Then 'the active main tab should be Home' do
    ensure_active_main_tab('Home')
  end

  Then 'the active main tab should be Projects' do
    ensure_active_main_tab('Projects')
  end

  Then 'the active main tab should be Groups' do
    ensure_active_main_tab('Groups')
  end

  Then 'the active main tab should be Users' do
    ensure_active_main_tab('Users')
  end

  Then 'the active main tab should be Logs' do
    ensure_active_main_tab('Logs')
  end

  Then 'the active main tab should be Hooks' do
    ensure_active_main_tab('Hooks')
  end

  Then 'the active main tab should be Resque' do
    ensure_active_main_tab('Background Jobs')
  end
end
