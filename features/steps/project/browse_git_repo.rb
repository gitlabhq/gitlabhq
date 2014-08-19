class ProjectBrowseGitRepo < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  Given 'I click on ".gitignore" file in repo' do
    click_link ".gitignore"
  end

  And 'I click blame button' do
    click_link "blame"
  end

  Then 'I should see git file blame' do
    page.should have_content "*.rb"
    page.should have_content "Dmitriy Zaporozhets"
    page.should have_content "Initial commit"
  end
end
