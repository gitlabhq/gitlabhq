class Spinach::Features::DashboardStarredProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I starred project "Community"' do
    current_user.toggle_star(Project.find_by(name: 'Community'))
  end

  step 'I should not see project "Shop"' do
    page.within '.projects-list' do
      expect(page).not_to have_content('Shop')
    end
  end
end
