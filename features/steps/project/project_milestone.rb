class Spinach::Features::ProjectMilestone < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedProject
  include SharedPaths

  step 'milestone has issue "Bugfix1" with labels: "bug", "feature"' do
    project = Project.find_by(name: "Shop")
    milestone = project.milestones.find_by(title: 'v2.2')
    issue = create(:issue, title: "Bugfix1", project: project, milestone: milestone)
    issue.labels << project.labels.find_by(title: 'bug')
    issue.labels << project.labels.find_by(title: 'feature')
  end

  step 'milestone has issue "Bugfix2" with labels: "bug", "enhancement"' do
    project = Project.find_by(name: "Shop")
    milestone = project.milestones.find_by(title: 'v2.2')
    issue = create(:issue, title: "Bugfix2", project: project, milestone: milestone)
    issue.labels << project.labels.find_by(title: 'bug')
    issue.labels << project.labels.find_by(title: 'enhancement')
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

  step 'I should see the list of labels' do
    expect(page).to have_selector('ul.manage-labels-list')
  end

  step 'I should see the labels "bug", "enhancement" and "feature"' do
    page.within('#tab-issues') do
      expect(page).to have_content 'bug'
      expect(page).to have_content 'enhancement'
      expect(page).to have_content 'feature'
    end
  end

  step 'I should see the "bug" label listed only once' do
    page.within('#tab-labels') do
      expect(page).to have_content('bug', count: 1)
    end
  end

  step 'I click link "v2.2"' do
    click_link "v2.2"
  end

  step 'I click link "Labels"' do
    page.within('.nav-links') do
      page.find(:xpath, "//a[@href='#tab-labels']").click
    end
  end
end
