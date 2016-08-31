class Spinach::Features::DashboardTodos < Spinach::FeatureSteps
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

  step 'I have todos' do
    create(:todo, user: current_user, project: project, author: mary_jane, target: issue, action: Todo::MENTIONED)
    create(:todo, user: current_user, project: project, author: john_doe, target: issue, action: Todo::ASSIGNED)
    note = create(:note, author: john_doe, noteable: issue, note: "#{current_user.to_reference} Wdyt?", project: project)
    create(:todo, user: current_user, project: project, author: john_doe, target: issue, action: Todo::MENTIONED, note: note)
    create(:todo, user: current_user, project: project, author: john_doe, target: merge_request, action: Todo::ASSIGNED)
  end

  step 'I should see todos assigned to me' do
    page.within('.todos-pending-count') { expect(page).to have_content '4' }
    expect(page).to have_content 'To do 4'
    expect(page).to have_content 'Done 0'

    expect(page).to have_link project.name_with_namespace
    should_see_todo(1, "John Doe assigned you merge request #{merge_request.to_reference}", merge_request.title)
    should_see_todo(2, "John Doe mentioned you on issue #{issue.to_reference}", "#{current_user.to_reference} Wdyt?")
    should_see_todo(3, "John Doe assigned you issue #{issue.to_reference}", issue.title)
    should_see_todo(4, "Mary Jane mentioned you on issue #{issue.to_reference}", issue.title)
  end

  step 'I mark the todo as done' do
    page.within('.todo:nth-child(1)') do
      click_link 'Done'
    end

    page.within('.todos-pending-count') { expect(page).to have_content '3' }
    expect(page).to have_content 'To do 3'
    expect(page).to have_content 'Done 1'
    should_not_see_todo "John Doe assigned you merge request #{merge_request.to_reference}"
  end

  step 'I mark all todos as done' do
    click_link 'Mark all as done'

    page.within('.todos-pending-count') { expect(page).to have_content '0' }
    expect(page).to have_content 'To do 0'
    expect(page).to have_content 'Done 4'
    expect(page).to have_content "You're all done!"
    expect(page).not_to have_link project.name_with_namespace
    should_not_see_todo "John Doe assigned you merge request #{merge_request.to_reference}"
    should_not_see_todo "John Doe mentioned you on issue #{issue.to_reference}"
    should_not_see_todo "John Doe assigned you issue #{issue.to_reference}"
    should_not_see_todo "Mary Jane mentioned you on issue #{issue.to_reference}"
  end

  step 'I should see the todo marked as done' do
    click_link 'Done 1'

    expect(page).to have_link project.name_with_namespace
    should_see_todo(1, "John Doe assigned you merge request #{merge_request.to_reference}", merge_request.title, false)
  end

  step 'I should see all todos marked as done' do
    click_link 'Done 4'

    expect(page).to have_link project.name_with_namespace
    should_see_todo(1, "John Doe assigned you merge request #{merge_request.to_reference}", merge_request.title, false)
    should_see_todo(2, "John Doe mentioned you on issue #{issue.to_reference}", "#{current_user.to_reference} Wdyt?", false)
    should_see_todo(3, "John Doe assigned you issue #{issue.to_reference}", issue.title, false)
    should_see_todo(4, "Mary Jane mentioned you on issue #{issue.to_reference}", issue.title, false)
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
    select2("#{Todo::MENTIONED}", from: '#action_id')
  end

  step 'I should not see todos' do
    expect(page).to have_content "You're all done!"
  end

  step 'I should not see todos related to "Mary Jane" in the list' do
    should_not_see_todo "Mary Jane mentioned you on issue #{issue.to_reference}"
  end

  step 'I should not see todos related to "Merge Requests" in the list' do
    should_not_see_todo "John Doe assigned you merge request #{merge_request.to_reference}"
  end

  step 'I should not see todos related to "Assignments" in the list' do
    should_not_see_todo "John Doe assigned you merge request #{merge_request.to_reference}"
    should_not_see_todo "John Doe assigned you issue #{issue.to_reference}"
  end

  step 'I click on the todo' do
    find('.todo:nth-child(1)').click
  end

  step 'I should be directed to the corresponding page' do
    page.should have_css('.identifier', text: 'Merge Request !1')
  end

  def should_see_todo(position, title, body, pending = true)
    page.within(".todo:nth-child(#{position})") do
      expect(page).to have_content title
      expect(page).to have_content body

      if pending
        expect(page).to have_link 'Done'
      else
        expect(page).not_to have_link 'Done'
      end
    end
  end

  def should_not_see_todo(title)
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
