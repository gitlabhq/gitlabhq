class Spinach::Features::DashboardTaskQueue < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedUser

  step '"John Doe" is a developer of project "Shop"' do
    project.team << [john_doe, :developer]
  end

  step 'I have pending tasks' do
    create(:task, user: current_user, project: project, author: john_doe, target: assigned_issue, action: Task::ASSIGNED)
  end

  step 'I should see pending tasks assigned to me' do
    expect(page).to have_link 'Tasks (1)'
    expect(page).to have_link 'Done (0)'

    page.within('.tasks') do
      expect(page).to have_content project.name_with_namespace
      expect(page).to have_content "John Doe assigned issue ##{assigned_issue.iid}"
      expect(page).to have_content(assigned_issue.title[0..10])
      expect(page).to have_link 'Done'
    end
  end

  step 'I mark the pending task as done' do
    click_link 'Done'

    expect(page).to have_content 'Task was successfully marked as done.'
    expect(page).to have_link 'Tasks (0)'
    expect(page).to have_link 'Done (1)'
    expect(page).to have_content 'No tasks to show'
  end

  step 'I click on the "Done" tab' do
    click_link 'Done (1)'
  end

  step 'I should see all tasks marked as done' do
    page.within('.tasks') do
      expect(page).to have_content project.name_with_namespace
      expect(page).to have_content "John Doe assigned issue ##{assigned_issue.iid}"
      expect(page).to have_content(assigned_issue.title[0..10])
      expect(page).not_to have_link 'Done'
    end
  end

  def assigned_issue
    @assigned_issue ||= create(:issue, assignee: current_user, project: project)
  end

  def john_doe
    @john_doe ||= user_exists("John Doe", { username: "john_doe" })
  end

  def project
    @project ||= create(:project, name: "Shop")
  end
end
