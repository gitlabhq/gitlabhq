# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User sorts work items", :js, feature_category: :team_planning do
  include Features::SortingHelpers
  include SortingHelper
  include FilteredSearchHelpers
  include IssueHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project_empty_repo, :public, group: group) }
  let_it_be_with_reload(:issue) { create(:issue, title: 'issue', created_at: Time.zone.now, project: project) }
  let_it_be_with_reload(:task) do
    create(:work_item, :task, title: 'task', created_at: Time.zone.now - 60, project: project)
  end

  let_it_be_with_reload(:incident) do
    create(:incident, title: 'incident', created_at: Time.zone.now - 120, project: project)
  end

  before_all do
    project.add_owner(user)
    project.add_developer(user2)
  end

  before do
    sign_in(user)
  end

  it 'sorts by newest' do
    visit project_work_items_path(project)

    expect(first_issue).to include('issue')
    expect(last_issue).to include('incident')
  end

  it 'sorts by most recently updated' do
    task.updated_at = Time.zone.now
    task.save!
    visit project_work_items_path(project)

    pajamas_sort_by 'Updated date', from: 'Created date'

    wait_for_requests

    expect(first_issue).to include('task')
  end

  describe 'sorting by dates' do
    before do
      task.update!(due_date: 1.day.from_now)
      issue.update!(due_date: 6.days.from_now)
      incident.update!(start_date: 8.days.from_now)
    end

    it 'sorts by start date' do
      visit project_work_items_path(project)

      pajamas_sort_by 'Start date', from: 'Created date'

      wait_for_requests

      expect(first_issue).to include('incident')
    end

    it 'sorts by due date' do
      visit project_work_items_path(project)

      pajamas_sort_by 'Due date', from: 'Created date'

      wait_for_requests

      expect(first_issue).to include('issue')
    end

    it 'sorts by due date reverse order' do
      visit project_work_items_path(project)

      pajamas_sort_by 'Due date', from: 'Created date'

      click_button _('Sort direction: Descending')

      wait_for_requests

      expect(first_issue).to include('task')
    end

    it 'sorts by due date by excluding nil due dates' do
      task.update!(due_date: nil)

      visit project_work_items_path(project)

      pajamas_sort_by 'Due date', from: 'Created date'

      wait_for_requests

      expect(first_issue).to include('issue')
    end
  end

  describe 'sorting by title' do
    it 'sorts by ascending' do
      visit project_work_items_path(project)

      pajamas_sort_by 'Title', from: 'Created date'

      click_button _('Sort direction: Descending')

      wait_for_requests

      expect(first_issue).to include('incident')
    end

    it 'sorts by descending' do
      visit project_work_items_path(project)

      pajamas_sort_by 'Title', from: 'Created date'

      wait_for_requests

      expect(first_issue).to include('task')
    end
  end

  describe 'combine filter and sort', :js do
    before do
      issue.assignees << user2
      issue.save!
      task.assignees << user2
      task.save!
    end

    it 'sorts with a filter applied' do
      visit project_work_items_path(project)

      select_tokens 'Assignee', '=', user2.username, submit: true

      pajamas_sort_by 'Title', from: 'Created date'

      wait_for_requests

      expect(first_issue).to include('task')
      expect(last_issue).to include('issue')
      expect(page).not_to have_content('incident')
    end
  end
end
