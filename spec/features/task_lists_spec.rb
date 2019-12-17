# frozen_string_literal: true

require 'spec_helper'

describe 'Task Lists' do
  include Warden::Test::Helpers

  let(:project) { create(:project, :repository) }
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

  let(:singleIncompleteMarkdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    MARKDOWN
  end

  let(:singleCompleteMarkdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [x] Incomplete entry 1
    MARKDOWN
  end

  let(:nested_tasks_markdown) do
    <<-EOT.strip_heredoc
    - [ ] Task a
      - [x] Task a.1
      - [ ] Task a.2
    - [ ] Task b

    1. [ ] Task 1
       1. [ ] Task 1.1
       1. [x] Task 1.2
    EOT
  end

  before do
    Warden.test_mode!

    project.add_maintainer(user)
    project.add_guest(user2)

    login_as(user)
  end

  def visit_issue(project, issue)
    visit project_issue_path(project, issue)
  end

  describe 'for Issues' do
    describe 'multiple tasks', :js do
      let!(:issue) { create(:issue, description: markdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 6)
        expect(page).to have_selector('ul input[checked]', count: 2)
      end

      it 'contains the required selectors' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector(".md .task-list .task-list-item .task-list-item-checkbox")
        expect(page).to have_selector('a.btn-close')
      end

      it 'is only editable by author' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector(".md .task-list .task-list-item .task-list-item-checkbox")

        logout(:user)
        login_as(user2)
        visit current_path
        wait_for_requests

        expect(page).to have_selector(".md .task-list .task-list-item .task-list-item-checkbox")
      end

      it 'provides a summary on Issues#index' do
        visit project_issues_path(project)
        expect(page).to have_content("2 of 6 tasks completed")
      end
    end

    describe 'single incomplete task', :js do
      let!(:issue) { create(:issue, description: singleIncompleteMarkdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 0)
      end

      it 'provides a summary on Issues#index' do
        visit project_issues_path(project)

        expect(page).to have_content("0 of 1 task completed")
      end
    end

    describe 'single complete task', :js do
      let!(:issue) { create(:issue, description: singleCompleteMarkdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 1)
      end

      it 'provides a summary on Issues#index' do
        visit project_issues_path(project)

        expect(page).to have_content("1 of 1 task completed")
      end
    end
  end

  describe 'for Notes' do
    let!(:issue) { create(:issue, author: user, project: project) }

    describe 'multiple tasks' do
      let!(:note) do
        create(:note, note: markdown, noteable: issue,
                      project: project, author: user)
      end

      it 'renders for note body', :js do
        visit_issue(project, issue)

        expect(page).to have_selector('.note ul.task-list',      count: 1)
        expect(page).to have_selector('.note li.task-list-item', count: 6)
        expect(page).to have_selector('.note ul input[checked]', count: 2)
      end

      it 'contains the required selectors', :js do
        visit_issue(project, issue)

        expect(page).to have_selector('.note .js-task-list-container')
        expect(page).to have_selector('.note .js-task-list-container .task-list .task-list-item .task-list-item-checkbox')
      end

      it 'is only editable by author', :js do
        visit_issue(project, issue)
        expect(page).to have_selector('.js-task-list-container')

        gitlab_sign_out

        gitlab_sign_in(user2)
        visit current_path
        expect(page).not_to have_selector('.js-task-list-container')
      end
    end

    describe 'single incomplete task' do
      let!(:note) do
        create(:note, note: singleIncompleteMarkdown, noteable: issue,
                      project: project, author: user)
      end

      it 'renders for note body', :js do
        visit_issue(project, issue)

        expect(page).to have_selector('.note ul.task-list',      count: 1)
        expect(page).to have_selector('.note li.task-list-item', count: 1)
        expect(page).to have_selector('.note ul input[checked]', count: 0)
      end
    end

    describe 'single complete task' do
      let!(:note) do
        create(:note, note: singleCompleteMarkdown, noteable: issue,
                      project: project, author: user)
      end

      it 'renders for note body', :js do
        visit_issue(project, issue)

        expect(page).to have_selector('.note ul.task-list',      count: 1)
        expect(page).to have_selector('.note li.task-list-item', count: 1)
        expect(page).to have_selector('.note ul input[checked]', count: 1)
      end
    end
  end

  describe 'for Merge Requests' do
    def visit_merge_request(project, merge)
      visit project_merge_request_path(project, merge)
    end

    describe 'multiple tasks' do
      let(:project) { create(:project, :repository) }
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
        expect(page).to have_selector("#{container} .md .task-list .task-list-item .task-list-item-checkbox")
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
        visit project_merge_requests_path(project)
        expect(page).to have_content("2 of 6 tasks completed")
      end
    end

    describe 'single incomplete task' do
      let!(:merge) { create(:merge_request, :simple, description: singleIncompleteMarkdown, author: user, source_project: project) }

      it 'renders for description' do
        visit_merge_request(project, merge)

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 0)
      end

      it 'provides a summary on MergeRequests#index' do
        visit project_merge_requests_path(project)
        expect(page).to have_content("0 of 1 task completed")
      end
    end

    describe 'single complete task' do
      let!(:merge) { create(:merge_request, :simple, description: singleCompleteMarkdown, author: user, source_project: project) }

      it 'renders for description' do
        visit_merge_request(project, merge)

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 1)
      end

      it 'provides a summary on MergeRequests#index' do
        visit project_merge_requests_path(project)
        expect(page).to have_content("1 of 1 task completed")
      end
    end
  end
end
