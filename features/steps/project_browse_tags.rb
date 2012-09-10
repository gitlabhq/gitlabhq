class ProjectBrowseTags < Spinach::FeatureSteps
  Then 'I should see "Shop" all tags list' do
    page.should have_content "Tags"
    page.should have_content "v1.2.1"
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  Given 'I visit project tags page' do
    visit tags_project_repository_path(@project)
  end
end
