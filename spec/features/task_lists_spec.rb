require 'spec_helper'

feature 'Task Lists', feature: true do
  include Warden::Test::Helpers

  let(:project) { create(:project) }
  let(:user)    { create(:user) }
  let(:user2)   { create(:user) }

  let(:markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    - [x] Complete entry 1
    - [ ] Incomplete entry 2
    - [x] Complete entry 2
    - [ ] Incomplete entry 3
    - [ ] Incomplete entry 4
    MARKDOWN
  end

  before do
    Warden.test_mode!

    project.team << [user, :master]
    project.team << [user2, :guest]

    login_as(user)
  end

  def visit_issue(project, issue)
    visit namespace_project_issue_path(project.namespace, project, issue)
  end

  describe 'for Issues' do
    let!(:issue) { create(:issue, description: markdown, author: user, project: project) }

    it 'renders' do
      visit_issue(project, issue)

      expect(page).to have_selector('ul.task-list',      count: 1)
      expect(page).to have_selector('li.task-list-item', count: 6)
      expect(page).to have_selector('ul input[checked]', count: 2)
    end

    it 'contains the required selectors' do
      visit_issue(project, issue)

      container = '.detail-page-description .description.js-task-list-container'

      expect(page).to have_selector(container)
      expect(page).to have_selector("#{container} .wiki .task-list .task-list-item .task-list-item-checkbox")
      expect(page).to have_selector("#{container} .js-task-list-field")
      expect(page).to have_selector('form.js-issuable-update')
      expect(page).to have_selector('a.btn-close')
    end

    it 'is only editable by author' do
      visit_issue(project, issue)
      expect(page).to have_selector('.js-task-list-container')

      logout(:user)

      login_as(user2)
      visit current_path
      expect(page).not_to have_selector('.js-task-list-container')
    end

    it 'provides a summary on Issues#index' do
      visit namespace_project_issues_path(project.namespace, project)
      expect(page).to have_content("6 tasks (2 completed, 4 remaining)")
    end
  end

  describe 'for Notes' do
    let!(:issue) { create(:issue, author: user, project: project) }
    let!(:note)  { create(:note, note: markdown, noteable: issue, author: user) }

    it 'renders for note body' do
      visit_issue(project, issue)

      expect(page).to have_selector('.note ul.task-list',      count: 1)
      expect(page).to have_selector('.note li.task-list-item', count: 6)
      expect(page).to have_selector('.note ul input[checked]', count: 2)
    end

    it 'contains the required selectors' do
      visit_issue(project, issue)

      expect(page).to have_selector('.note .js-task-list-container')
      expect(page).to have_selector('.note .js-task-list-container .task-list .task-list-item .task-list-item-checkbox')
      expect(page).to have_selector('.note .js-task-list-container .js-task-list-field')
    end

    it 'is only editable by author' do
      visit_issue(project, issue)
      expect(page).to have_selector('.js-task-list-container')

      logout(:user)

      login_as(user2)
      visit current_path
      expect(page).not_to have_selector('.js-task-list-container')
    end
  end

  describe 'for Merge Requests' do
    def visit_merge_request(project, merge)
      visit namespace_project_merge_request_path(project.namespace, project, merge)
    end

    let!(:merge) { create(:merge_request, :simple, description: markdown, author: user, source_project: project) }

    it 'renders for description' do
      visit_merge_request(project, merge)

      expect(page).to have_selector('ul.task-list',      count: 1)
      expect(page).to have_selector('li.task-list-item', count: 6)
      expect(page).to have_selector('ul input[checked]', count: 2)
    end

    it 'contains the required selectors' do
      visit_merge_request(project, merge)

      container = '.detail-page-description .description.js-task-list-container'

      expect(page).to have_selector(container)
      expect(page).to have_selector("#{container} .wiki .task-list .task-list-item .task-list-item-checkbox")
      expect(page).to have_selector("#{container} .js-task-list-field")
      expect(page).to have_selector('form.js-issuable-update')
      expect(page).to have_selector('a.btn-close')
    end

    it 'is only editable by author' do
      visit_merge_request(project, merge)
      expect(page).to have_selector('.js-task-list-container')

      logout(:user)

      login_as(user2)
      visit current_path
      expect(page).not_to have_selector('.js-task-list-container')
    end

    it 'provides a summary on MergeRequests#index' do
      visit namespace_project_merge_requests_path(project.namespace, project)
      expect(page).to have_content("6 tasks (2 completed, 4 remaining)")
    end
  end
end
