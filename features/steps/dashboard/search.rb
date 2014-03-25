class DashboardSearch < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  Given 'I search for "Sho"' do
    fill_in "dashboard_search", with: "Sho"
    click_button "Search"
  end

  Then 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end

  Given 'I search for "Contibuting"' do
    fill_in "dashboard_search", with: "Contibuting"
    click_button "Search"
  end
end
