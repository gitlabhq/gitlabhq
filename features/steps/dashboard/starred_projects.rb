class Spinach::Features::DashboardStarredProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I should see "Your Projects"' do
    expect(page).to have_link 'Your Projects'
  end

  step 'I should see "Starred Projects"' do
    expect(page).to have_link 'Starred Projects'
  end
end
