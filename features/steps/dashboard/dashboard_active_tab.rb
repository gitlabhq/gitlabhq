class DashboardActiveTab < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedActiveTab

  Then 'the active main tab should be Home' do
    ensure_active_main_tab('Home')
  end

  Then 'the active main tab should be Issues' do
    ensure_active_main_tab('Issues')
  end

  Then 'the active main tab should be Merge Requests' do
    ensure_active_main_tab('Merge Requests')
  end

  Then 'the active main tab should be Search' do
    ensure_active_main_tab('Search')
  end

  Then 'the active main tab should be Help' do
    ensure_active_main_tab('Help')
  end
end
