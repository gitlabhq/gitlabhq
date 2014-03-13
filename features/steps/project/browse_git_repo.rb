class ProjectBrowseGitRepo < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Given 'I click on "Gemfile.lock" file in repo' do
    click_link "Gemfile.lock"
  end

  And 'I click blame button' do
    click_link "blame"
  end

  Then 'I should see git file blame' do
    page.should have_content "DEPENDENCIES"
    page.should have_content "Dmitriy Zaporozhets"
    page.should have_content "Moving to rails 3.2"
  end
end
