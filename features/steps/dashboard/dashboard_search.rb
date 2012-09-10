class DashboardSearch < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths

  Given 'I search for "Sho"' do
    fill_in "dashboard_search", :with => "Sho"
    click_button "Search"
  end

  Then 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end
end
