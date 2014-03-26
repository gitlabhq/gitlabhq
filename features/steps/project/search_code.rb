class ProjectSearchCode < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  When 'I search for term "Welcome to GitLab"' do
    fill_in "search", with: "Welcome to GitLab"
    click_button "Go"
    click_link 'Repository Code'
  end

  Then 'I should see files from repository containing "Welcome to GitLab"' do
    page.should have_content "Welcome to GitLab"
    page.should have_content "GitLab is a free project and repository management application"
  end

end
