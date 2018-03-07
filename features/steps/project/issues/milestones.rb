class Spinach::Features::ProjectIssuesMilestones < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths
  include SharedMarkdown

  step 'I should see milestone "v2.2"' do
    milestone = @project.milestones.find_by(title: "v2.2")
    expect(page).to have_content(milestone.title[0..10])
    expect(page).to have_content(milestone.expires_at)
    expect(page).to have_content("Issues")
  end

  step 'I click link "v2.2"' do
    click_link "v2.2"
  end

  step 'I click link "New Milestone"' do
    page.within('.nav-controls') do
      click_link "New milestone"
    end
  end

  step 'I submit new milestone "v2.3"' do
    fill_in "milestone_title", with: "v2.3"
    click_button "Create milestone"
  end

  step 'I should see milestone "v2.3"' do
    milestone = @project.milestones.find_by(title: "v2.3")
    expect(page).to have_content(milestone.title[0..10])
    expect(page).to have_content(milestone.expires_at)
    expect(page).to have_content("Issues")
  end

  step 'project "Shop" has milestone "v2.2"' do
    project = Project.find_by(name: "Shop")
    milestone = create(:milestone,
                       title: "v2.2",
                       project: project,
                       description: "# Description header"
                      )
    3.times { create(:issue, project: project, milestone: milestone) }
  end

  step 'the milestone has open and closed issues' do
    project = Project.find_by(name: "Shop")
    milestone = project.milestones.find_by(title: 'v2.2')

    # 3 Open issues created above; create one closed issue
    create(:closed_issue, project: project, milestone: milestone)
  end

  step 'I should see deleted milestone activity' do
    expect(page).to have_content('opened milestone in')
    expect(page).to have_content('destroyed milestone in')
  end

  When 'I click link "All Issues"' do
    click_link 'All Issues'
  end

  step 'I should see 3 issues' do
    expect(page).to have_selector('#tab-issues li.issuable-row', count: 4)
  end

  step 'I click button to remove milestone' do
    click_button 'Delete'
  end

  step 'I confirm in modal' do
    click_button 'Delete milestone'
  end

  step 'I should see no milestones' do
    expect(page).to have_content('No milestones to show')
  end
end
