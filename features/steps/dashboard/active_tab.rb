class Spinach::Features::DashboardActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  step 'the active main tab should be Help' do
    ensure_active_main_tab('Help')
  end
end
