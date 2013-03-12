class Dashboard < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  Then 'I should see projects list' do
    @user.authorized_projects.all.each do |project|
      page.should have_link project.name_with_namespace
    end
  end

  Given 'I search for "Sho"' do
    fill_in "dashboard_projects_search", with: "Sho"

    within ".dashboard-search-filter" do
      find('button').click
    end
  end

  Then 'I should see "Shop" project link' do
    page.should have_link "Shop"
  end
end
