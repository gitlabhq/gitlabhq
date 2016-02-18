class Spinach::Features::DashboardTaskQueue < Spinach::FeatureSteps
  include SharedAuthentication
  include SharedPaths
  include SharedProject
  include SharedUser
  include Select2Helper

  step '"John Doe" is a developer of project "Shop"' do
    project.team << [john_doe, :developer]
  end

  step 'I am a developer of project "Enterprise"' do
    enterprise.team << [current_user, :developer]
  end

  step '"Mary Jane" is a developer of project "Shop"' do
    project.team << [john_doe, :developer]
  end

  step 'I have pending tasks' do
    create(:task, user: current_user, project: project, author: mary_jane, target: issue, action: Task::MENTIONED)
    create(:task, user: current_user, project: project, author: john_doe, target: issue, action: Task::ASSIGNED)
    note = create(:note, author: john_doe, noteable: issue, note: "#{current_user.to_reference} Wdyt?")
    create(:task, user: current_user, project: project, author: john_doe, target: issue, action: Task::MENTIONED, note: note)
    create(:task, user: current_user, project: project, author: john_doe, target: merge_request, action: Task::ASSIGNED)
  end

  step 'I should see pending tasks assigned to me' do
    expect(page).to have_content 'Tasks 4'
    expect(page).to have_content 'Done 0'

    expect(page).to have_link project.name_with_namespace
    should_see_task(1, "John Doe assigned merge request ##{merge_request.iid}", merge_request.title)
    should_see_task(2, "John Doe mentioned you on issue ##{issue.iid}", "#{current_user.to_reference} Wdyt?")
    should_see_task(3, "John Doe assigned issue ##{issue.iid}", issue.title)
    should_see_task(4, "Mary Jane mentioned you on issue ##{issue.iid}", issue.title)
  end

  step 'I mark the pending task as done' do
    page.within('.task:nth-child(1)') do
      click_link 'Done'
    end

    expect(page).to have_content 'Task was successfully marked as done.'
    expect(page).to have_content 'Tasks 3'
    expect(page).to have_content 'Done 1'
    should_not_see_task "John Doe assigned merge request ##{merge_request.iid}"
  end

  step 'I click on the "Done" tab' do
    click_link 'Done 1'
  end

  step 'I should see all tasks marked as done' do
    expect(page).to have_link project.name_with_namespace
    should_see_task(1, "John Doe assigned merge request ##{merge_request.iid}", merge_request.title, false)
  end

  step 'I filter by "Enterprise"' do
    select2(enterprise.id, from: "#project_id")
  end

  step 'I filter by "John Doe"' do
    select2(john_doe.id, from: "#author_id")
  end

  step 'I filter by "Issue"' do
    select2('Issue', from: "#type")
  end

  step 'I filter by "Mentioned"' do
    select2("#{Task::MENTIONED}", from: '#action_id')
  end

  step 'I should not see tasks' do
    expect(page).to have_content 'No tasks to show'
  end

  step 'I should not see tasks related to "Mary Jane" in the list' do
    should_not_see_task "Mary Jane mentioned you on issue ##{issue.iid}"
  end

  step 'I should not see tasks related to "Merge Requests" in the list' do
    should_not_see_task "John Doe assigned merge request ##{merge_request.iid}"
  end

  step 'I should not see tasks related to "Assignments" in the list' do
    should_not_see_task "John Doe assigned merge request ##{merge_request.iid}"
    should_not_see_task "John Doe assigned issue ##{issue.iid}"
  end

  def should_see_task(position, title, body, pending = true)
    page.within(".task:nth-child(#{position})") do
      expect(page).to have_content title
      expect(page).to have_content body

      if pending
        expect(page).to have_link 'Done'
      else
        expect(page).to_not have_link 'Done'
      end
    end
  end

  def should_not_see_task(title)
    expect(page).not_to have_content title
  end

  def john_doe
    @john_doe ||= user_exists("John Doe", { username: "john_doe" })
  end

  def mary_jane
    @mary_jane ||= user_exists("Mary Jane", { username: "mary_jane" })
  end

  def enterprise
    @enterprise ||= Project.find_by(name: 'Enterprise')
  end

  def issue
    @issue ||= create(:issue, assignee: current_user, project: project)
  end

  def merge_request
    @merge_request ||= create(:merge_request, assignee: current_user, source_project: project)
  end
end
