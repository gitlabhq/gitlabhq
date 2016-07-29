class Spinach::Features::GroupAnalytics < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser

  step 'I click on group analytics' do
    click_link 'Contribution Analytics'
  end

  step 'I should see group analytics page' do
    expect(page).to have_content "Contribution analytics for issues, merge requests and push"
  end
end
