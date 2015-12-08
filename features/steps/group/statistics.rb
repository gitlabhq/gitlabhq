class Spinach::Features::GroupStatistics < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser

  step 'I click on group statistics' do
    click_link 'Statistics'
  end

  step 'I should see group statistics page' do
    expect(page).to have_content "Contribution statistics for issues, merge requests and push"
  end
end
