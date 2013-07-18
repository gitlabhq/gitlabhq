class ProjectBrowseBranches < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

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
    within ".protected-branches-list" do
      page.should have_content "stable"
      page.should_not have_content "master"
    end
  end

  And 'project "Shop" has protected branches' do
    project = Project.find_by_name("Shop")
    project.protected_branches.create(name: "stable")
  end
end
