class Spinach::Features::GroupMilestones < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedGroup
  include SharedUser

  step 'I click on group milestones' do
    click_link 'Milestones'
  end

  step 'I should see group milestones index page has no milestones' do
    expect(page).to have_content('No milestones to show')
  end

  step 'Group has projects with milestones' do
    group_milestone
  end

  step 'I should see group milestones index page with milestones' do
    expect(page).to have_content('Version 7.2')
    expect(page).to have_content('GL-113')
    expect(page).to have_link('3 Issues', href: issues_group_path("owned", milestone_title: "Version 7.2"))
    expect(page).to have_link('0 Merge Requests', href: merge_requests_group_path("owned", milestone_title: "GL-113"))
  end

  step 'I click on one group milestone' do
    click_link 'GL-113'
  end

  step 'I should see group milestone with descriptions and expiry date' do
    expect(page).to have_content('expires at Aug 20, 2114')
  end

  step 'I should see group milestone with all issues and MRs assigned to that milestone' do
    expect(page).to have_content('Milestone GL-113')
    expect(page).to have_content('Progress: 0 closed – 3 open')
    issue = Milestone.find_by(name: 'GL-113').issues.first
    expect(page).to have_link(issue.title, href: namespace_project_issue_path(issue.project.namespace, issue.project, issue))
  end

  step 'I fill milestone name' do
    fill_in 'milestone_title', with: 'v2.9.0'
  end

  step 'I click new milestone button' do
    click_link "New Milestone"
  end

  step 'I press create mileston button' do
    click_button "Create Milestone"
  end

  step 'milestone in each project should be created' do
    group = Group.find_by(name: 'Owned')
    expect(page).to have_content "Milestone v2.9.0"
    expect(group.projects).to be_present

    group.projects.each do |project|
      expect(page).to have_content project.name
    end
  end

  private

  def group_milestone
    group = owned_group

    %w(gitlabhq gitlab-ci cookbook-gitlab).each do |path|
      project = create :project, path: path, group: group
      milestone = create :milestone, title: "Version 7.2", project: project
      create :issue,
        project: project,
        assignee: current_user,
        author: current_user,
        milestone: milestone

      milestone = create :milestone,
        title: "GL-113",
        project: project,
        due_date: '2114-08-20',
        description: 'Lorem Ipsum is simply dummy text'

      create :issue,
        project: project,
        assignee: current_user,
        author: current_user,
        milestone: milestone
    end
  end
end
