class ProjectMilestones < Spinach::FeatureSteps
  Then 'I should see milestone "v2.2"' do
    milestone = @project.milestones.find_by_title("v2.2")
    page.should have_content(milestone.title[0..10])
    page.should have_content(milestone.expires_at)
    page.should have_content("Browse Issues")
  end

  Given 'I click link "v2.2"' do
    click_link "v2.2"
  end

  Given 'I click link "New Milestone"' do
    click_link "New Milestone"
  end

  And 'I submit new milestone "v2.3"' do
    fill_in "milestone_title", :with => "v2.3"
    click_button "Create milestone"
  end

  Then 'I should see milestone "v2.3"' do
    milestone = @project.milestones.find_by_title("v2.3")
    page.should have_content(milestone.title[0..10])
    page.should have_content(milestone.expires_at)
    page.should have_content("Browse Issues")
  end

  Given 'I sign in as a user' do
    login_as :user
  end

  And 'I own project "Shop"' do
    @project = Factory :project, :name => "Shop"
    @project.add_access(@user, :admin)
  end

  And 'project "Shop" has milestone "v2.2"' do
    project = Project.find_by_name("Shop")
    milestone = Factory :milestone, :title => "v2.2", :project => project

    3.times do
      issue = Factory :issue, :project => project, :milestone => milestone
    end
  end

  Given 'I visit project "Shop" milestones page' do
    @project = Project.find_by_name("Shop")
    visit project_milestones_path(@project)
  end
end
