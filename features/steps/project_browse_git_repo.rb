class ProjectBrowseGitRepo < Spinach::FeatureSteps
  Given 'I click on "Gemfile" file in repo' do
    click_link "Gemfile"
  end

  And 'I click blame button' do
    click_link "blame"
  end

  Then 'I should see git file blame' do
    page.should have_content "rubygems.org"
    page.should have_content "Dmitriy Zaporozhets"
    page.should have_content "bc3735004cb Moving to rails 3.2"
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  Given 'I visit project source page' do
    visit tree_project_ref_path(@project, @project.root_ref)
  end
end
