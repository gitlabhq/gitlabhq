class Spinach::Features::DashboardProjects < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject

  step 'I should see "Your Projects (3)"' do
    expect(page).to have_link 'Your Projects (3)'
  end

  step 'I should see "Starred Projects (2)"' do
    expect(page).to have_link 'Starred Projects (2)'
  end
end
