class ProjectBrowseBranches < Spinach::FeatureSteps
  Then 'I should see "Shop" recent branches list' do
    page.should have_content "Branches"
    page.should have_content "master"
  end

  Given 'I click link "All"' do
    click_link "All"
  end

  Then 'I should see "Shop" all branches list' do
    page.should have_content "Branches"
    page.should have_content "master"
  end

  Given 'I click link "Protected"' do
    click_link "Protected"
  end

  Then 'I should see "Shop" protected branches list' do
    within "table" do
      page.should have_content "stable"
      page.should_not have_content "master"
    end
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  And 'project "Shop" has protected branches' do
    project = Project.find_by_name("Shop")
    project.protected_branches.create(:name => "stable")
  end

  Given 'I visit project branches page' do
    visit branches_project_repository_path(@project)
  end
end
