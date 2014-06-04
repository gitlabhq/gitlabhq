class ProjectMilestones < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include SharedMarkdown

  Then 'I should see milestone "v2.2"' do
    milestone = @project.milestones.find_by(title: "v2.2")
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
    fill_in "milestone_title", with: "v2.3"
    click_button "Create milestone"
  end

  Then 'I should see milestone "v2.3"' do
    milestone = @project.milestones.find_by(title: "v2.3")
    page.should have_content(milestone.title[0..10])
    page.should have_content(milestone.expires_at)
    page.should have_content("Browse Issues")
  end

  And 'project "Shop" has milestone "v2.2"' do
    project = Project.find_by(name: "Shop")
    milestone = create(:milestone,
                       title: "v2.2",
                       project: project,
                       description: "# Description header"
                      )
    3.times { create(:issue, project: project, milestone: milestone) }
  end

  Given 'the milestone has open and closed issues' do
    project = Project.find_by(name: "Shop")
    milestone = project.milestones.find_by(title: 'v2.2')

    # 3 Open issues created above; create one closed issue
    create(:closed_issue, project: project, milestone: milestone)
  end

  When 'I click link "All Issues"' do
    click_link 'All Issues'
  end

  Then "I should see 3 issues" do
    page.should have_selector('#tab-issues li.issue-row', count: 4)
  end
end
