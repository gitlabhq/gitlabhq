class DashboardSearch < Spinach::FeatureSteps
  Given 'I search for "Sho"' do
    fill_in "dashboard_search", :with => "Sho"
    click_button "Search"
  end

  Then 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  And 'I visit dashboard search page' do
    visit search_path
  end
end
