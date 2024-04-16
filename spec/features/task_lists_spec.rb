# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Task Lists', :js, feature_category: :team_planning do
  include Warden::Test::Helpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:user)    { create(:user, maintainer_of: project) }
  let_it_be(:user2)   { create(:user, guest_of: project) }

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

  let(:single_incomplete_markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [ ] Incomplete entry 1
    MARKDOWN
  end

  let(:single_complete_markdown) do
    <<-MARKDOWN.strip_heredoc
    This is a task list:

    - [x] Incomplete entry 1
    MARKDOWN
  end

  before do
    sign_in(user)
  end

  def visit_issue(project, issue)
    visit project_issue_path(project, issue)
  end

  describe 'for Issues' do
    describe 'multiple tasks' do
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
        expect(page).to have_selector('.btn-close')
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

        expect(page).to have_content("2 of 6 checklist items completed")
      end
    end

    describe 'single incomplete task' do
      let!(:issue) { create(:issue, description: single_incomplete_markdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 0)
      end

      it 'provides a summary on Issues#index' do
        visit project_issues_path(project)

        expect(page).to have_content("0 of 1 checklist item completed")
      end
    end

    describe 'single complete task' do
      let!(:issue) { create(:issue, description: single_complete_markdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 1)
      end

      it 'provides a summary on Issues#index' do
        visit project_issues_path(project)

        expect(page).to have_content("1 of 1 checklist item completed")
      end
    end
  end

  describe 'for Notes' do
    let!(:issue) { create(:issue, author: user, project: project) }

    describe 'multiple tasks' do
      let!(:note) do
        create(:note, note: markdown, noteable: issue, project: project, author: user)
      end

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
      end

      it 'is only editable by author' do
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
        create(:note, note: single_incomplete_markdown, noteable: issue, project: project, author: user)
      end

      it 'renders for note body' do
        visit_issue(project, issue)

        expect(page).to have_selector('.note ul.task-list',      count: 1)
        expect(page).to have_selector('.note li.task-list-item', count: 1)
        expect(page).to have_selector('.note ul input[checked]', count: 0)
      end
    end

    describe 'single complete task' do
      let!(:note) do
        create(:note, note: single_complete_markdown, noteable: issue, project: project, author: user)
      end

      it 'renders for note body' do
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

    shared_examples 'multiple tasks' do
      it 'renders for description' do
        visit_merge_request(project, merge)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 6)
        expect(page).to have_selector('ul input[checked]', count: 2)
      end

      it 'contains the required selectors' do
        visit_merge_request(project, merge)
        wait_for_requests

        container = '.detail-page-description .description.js-task-list-container'

        expect(page).to have_selector(container)
        expect(page).to have_selector("#{container} .md .task-list .task-list-item .task-list-item-checkbox")
        expect(page).to have_selector("#{container} .js-task-list-field", visible: false)
        expect(page).to have_selector('form.js-issuable-update')
      end

      it 'is only editable by author' do
        visit_merge_request(project, merge)
        wait_for_requests

        expect(page).to have_selector('.js-task-list-container')
        expect(page).to have_selector('li.task-list-item.enabled', count: 6)

        logout(:user)
        login_as(user2)
        visit current_path
        wait_for_requests

        expect(page).not_to have_selector('.js-task-list-container')
        expect(page).to have_selector('li.task-list-item.enabled', count: 0)
        expect(page).to have_selector('li.task-list-item input[disabled]', count: 6)
      end
    end

    context 'when merge request is open' do
      let!(:merge) { create(:merge_request, :simple, description: markdown, author: user, source_project: project) }

      it_behaves_like 'multiple tasks'

      it 'provides a summary on MergeRequests#index' do
        visit project_merge_requests_path(project)

        expect(page).to have_content("2 of 6 checklist items completed")
      end
    end

    context 'when merge request is closed' do
      let!(:merge) { create(:merge_request, :closed, :simple, description: markdown, author: user, source_project: project) }

      it_behaves_like 'multiple tasks'
    end

    describe 'single incomplete task' do
      let!(:merge) { create(:merge_request, :simple, description: single_incomplete_markdown, author: user, source_project: project) }

      it 'renders for description' do
        visit_merge_request(project, merge)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 0)
      end

      it 'provides a summary on MergeRequests#index' do
        visit project_merge_requests_path(project)

        expect(page).to have_content("0 of 1 checklist item completed")
      end
    end

    describe 'single complete task' do
      let!(:merge) { create(:merge_request, :simple, description: single_complete_markdown, author: user, source_project: project) }

      it 'renders for description' do
        visit_merge_request(project, merge)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 1)
      end

      it 'provides a summary on MergeRequests#index' do
        visit project_merge_requests_path(project)

        expect(page).to have_content("1 of 1 checklist item completed")
      end
    end
  end

  describe 'markdown task edge cases' do
    describe 'commented tasks' do
      let(:commented_tasks_markdown) do
        <<-EOT.strip_heredoc
        <!-- comment text -->

        text

        <!-- - [ ] commented out task -->

        <!--
        - [ ] a
        -->

        - [ ] b
        EOT
      end

      let!(:issue) { create(:issue, description: commented_tasks_markdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 0)

        find('.task-list-item-checkbox').click
        wait_for_requests

        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 1)
        expect(page).to have_content('1 of 1 checklist item completed')
      end
    end

    describe 'tasks in code blocks' do
      let(:code_tasks_markdown) do
        <<-EOT.strip_heredoc
        ```
        - [ ] a
        ```

        - [ ] b
        EOT
      end

      let!(:issue) { create(:issue, description: code_tasks_markdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 0)

        find('.task-list-item-checkbox').click
        wait_for_requests

        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 1)
        expect(page).to have_content('1 of 1 checklist item completed')
      end
    end

    describe 'summary with no blank line' do
      let(:summary_no_blank_line_markdown) do
        <<-EOT.strip_heredoc
        <details>
        <summary>No blank line after summary element breaks task list</summary>
        1. [ ] People Ops: do such and such
        </details>

        * [ ] Task 1
        EOT
      end

      let!(:issue) { create(:issue, description: summary_no_blank_line_markdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 0)

        find('.task-list-item-checkbox').click
        wait_for_requests

        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 1)
        expect(page).to have_selector('li.task-list-item', count: 1)
        expect(page).to have_selector('ul input[checked]', count: 1)
      end
    end

    describe 'summary properly formatted' do
      let(:summary_markdown) do
        <<-EOT.strip_heredoc
        <details open>
        <summary>Valid detail/summary with tasklist</summary>

        - [ ] People Ops: do such and such

        </details>

        * [x] Task 1
        EOT
      end

      let!(:issue) { create(:issue, description: summary_markdown, author: user, project: project) }

      it 'renders' do
        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 2)
        expect(page).to have_selector('li.task-list-item', count: 2)
        expect(page).to have_selector('ul input[checked]', count: 1)

        first('.task-list-item-checkbox').click
        wait_for_requests

        visit_issue(project, issue)
        wait_for_requests

        expect(page).to have_selector('ul.task-list',      count: 2)
        expect(page).to have_selector('li.task-list-item', count: 2)
        expect(page).to have_selector('ul input[checked]', count: 2)
        expect(page).to have_content('2 of 2 checklist items completed')
      end
    end

    describe 'markdown starting with new line character' do
      let(:markdown_starting_with_new_line) do
        <<-EOT.strip_heredoc

        - [ ] Task 1
        EOT
      end

      let(:merge_request) { create(:merge_request, description: markdown_starting_with_new_line, author: user, source_project: project) }

      it 'allows the task to be checked' do
        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        expect(page).to have_selector('ul input[checked]', count: 0)

        find('.task-list-item-checkbox').click
        wait_for_requests

        visit project_merge_request_path(project, merge_request)
        wait_for_requests

        expect(page).to have_selector('ul input[checked]', count: 1)
      end
    end
  end
end
