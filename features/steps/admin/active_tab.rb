class Spinach::Features::AdminActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  step 'the active main tab should be Overview' do
    ensure_active_main_tab('Overview')
  end

  step 'the active sub tab should be Projects' do
    ensure_active_sub_tab('Projects')
  end

  step 'the active sub tab should be Groups' do
    ensure_active_sub_tab('Groups')
  end

  step 'the active sub tab should be Users' do
    ensure_active_sub_tab('Users')
  end

  step 'the active main tab should be Hooks' do
    ensure_active_main_tab('Hooks')
  end

  step 'the active main tab should be Monitoring' do
    ensure_active_main_tab('Monitoring')
  end

  step 'the active sub tab should be Resque' do
    ensure_active_sub_tab('Background Jobs')
  end

  step 'the active sub tab should be Logs' do
    ensure_active_sub_tab('Logs')
  end

  step 'the active main tab should be Messages' do
    ensure_active_main_tab('Messages')
  end
end
