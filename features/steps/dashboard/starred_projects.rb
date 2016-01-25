class Spinach::Features::DashboardStarredProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I should see "Your Projects (4)"' do
    expect(page).to have_link 'Your Projects (4)'
  end

  step 'I should see "Starred Projects (3)"' do
    expect(page).to have_link 'Starred Projects (3)'
  end
end
