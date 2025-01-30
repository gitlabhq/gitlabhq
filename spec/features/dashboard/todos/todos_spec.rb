# frozen_string_literal: true

# covered by ./accessibility_spec.rb

require 'spec_helper'

RSpec.describe 'Dashboard Todos', :js, feature_category: :notifications do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user, name: 'Michael Scott') }
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public, developers: user) }
  let_it_be(:issue) { create(:issue, project: project, due_date: Date.today, title: "Fix bug") }
  let_it_be(:issue2) { create(:issue, project: project, due_date: Date.today, title: "Update gems") }
  let_it_be(:issue3) { create(:issue, project: project, due_date: Date.today, title: "Deploy feature") }

  before do
    sign_in user
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_todos_path, :todos

  context 'when the todo references a merge request' do
    let(:referenced_mr) { create(:merge_request, source_project: project) }
    let(:note) { create(:note, project: project, note: "Check out #{referenced_mr.to_reference}", noteable: create(:issue, project: project)) }
    let!(:todo) { create(:todo, :mentioned, user: user, project: project, author: author, note: note, target: note.noteable) }

    before do
      visit dashboard_todos_path
    end

    it 'renders the mr reference' do
      expect(page).to have_content(referenced_mr.to_reference)
    end
  end

  context 'user has an unauthorized todo' do
    it 'does not render the todo' do
      unauthorized_issue = create(:issue)
      create(:todo, :mentioned, user: user, project: unauthorized_issue.project, target: unauthorized_issue, author: author)
      create(:todo, :mentioned, user: user, project: project, target: issue, author: author)

      visit dashboard_todos_path

      expect(page).to have_selector('ol[data-testid="todo-item-list"] > li', count: 1)
    end
  end

  context 'User has a todo' do
    context 'when todo has a note' do
      let(:note) { create(:note, project: project, note: "Check out stuff", noteable: create(:issue, project: project)) }
      let!(:todo) { create(:todo, :mentioned, user: user, project: project, author: author, note: note, target: note.noteable) }

      before do
        visit dashboard_todos_path
      end

      it 'shows note preview' do
        expect(page).to have_no_content('mentioned you:')
        expect(page).to have_no_content('"Check out stuff"')
        expect(page).to have_content('Check out stuff')
      end
    end
  end

  context 'User created todos for themself' do
    context 'issue assigned todo' do
      before do
        create(:todo, :assigned, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows issue assigned to yourself message' do
        within_testid('todo-item-list-container') do
          expect(page).to have_content("Fix bug · #{project.namespace.owner_name} / #{project.name} #{issue.to_reference}")
          expect(page).to have_content("You assigned to yourself.")
        end
      end
    end

    context 'marked todo' do
      before do
        create(:todo, :marked, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows you added a to-do item message' do
        within_testid('todo-item-list-container') do
          expect(page).to have_content("Fix bug · #{project.namespace.owner_name} / #{project.name} #{issue.to_reference}")
          expect(page).to have_content("You added a to-do item.")
        end
      end
    end

    context 'mentioned todo' do
      before do
        create(:todo, :mentioned, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows you mentioned yourself message' do
        within_testid('todo-item-list-container') do
          expect(page).to have_content("Fix bug · #{project.namespace.owner_name} / #{project.name} #{issue.to_reference}")
          expect(page).to have_content("You mentioned yourself.")
        end
      end
    end

    context 'directly_addressed todo' do
      before do
        create(:todo, :directly_addressed, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows you directly addressed yourself message being displayed as mentioned yourself' do
        within_testid('todo-item-list-container') do
          expect(page).to have_content("Fix bug · #{project.namespace.owner_name} / #{project.name} #{issue.to_reference}")
          expect(page).to have_content("You mentioned yourself.")
        end
      end
    end

    context 'approval todo' do
      let(:merge_request) { create(:merge_request, title: "Fixes issue", source_project: project) }

      before do
        create(:todo, :approval_required, user: user, project: project, target: merge_request, author: user)
        visit dashboard_todos_path
      end

      it 'shows you set yourself as an approver message' do
        within_testid('todo-item-list-container') do
          expect(page).to have_content("Fixes issue · #{project.namespace.owner_name} / #{project.name} #{merge_request.to_reference}")
          expect(page).to have_content("You set yourself as an approver.")
        end
      end
    end

    context 'review request todo' do
      let(:merge_request) { create(:merge_request, title: "Fixes issue", source_project: project) }

      before do
        create(:todo, :review_requested, user: user, project: project, target: merge_request, author: user)
        visit dashboard_todos_path
      end

      it 'shows you set yourself as an reviewer message' do
        within_testid('todo-item-list-container') do
          expect(page).to have_content("Fixes issue · #{project.namespace.owner_name} / #{project.name} #{merge_request.to_reference}")
          expect(page).to have_content("You requested a review from yourself.")
        end
      end
    end
  end

  context 'User has automatically created todos' do
    before do
      sign_in(user)
    end

    context 'unmergeable todo' do
      before do
        create(:todo, :unmergeable, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows unmergeable message' do
        within_testid('todo-item-list-container') do
          expect(page).to have_content("Fix bug · #{project.namespace.owner_name} / #{project.name} #{issue.to_reference}")
          expect(page).to have_content("Could not merge.")
        end
      end
    end
  end

  context 'User has to dos with labels spanning multiple projects' do
    before do
      label1 = create(:label, project: project)
      note1 = create(:note_on_issue, note: "Hello #{label1.to_reference(format: :name)}", noteable_id: issue.id, noteable_type: 'Issue', project: issue.project)
      create(:todo, :mentioned, project: project, target: issue, user: user, note_id: note1.id)

      project2 = create(:project, :public)
      label2 = create(:label, project: project2)
      issue2 = create(:issue, project: project2)
      note2 = create(:note_on_issue, note: "Test #{label2.to_reference(format: :name)}", noteable_id: issue2.id, noteable_type: 'Issue', project: project2)
      create(:todo, :mentioned, project: project2, target: issue2, user: user, note_id: note2.id)

      visit dashboard_todos_path
    end

    it 'shows page with two Todos' do
      expect(page).to have_selector('ol[data-testid="todo-item-list"] > li', count: 2)
    end
  end

  context 'User has a Build Failed todo' do
    let!(:todo) { create(:todo, :build_failed, user: user, project: project, author: author, target: create(:merge_request, source_project: project)) }

    before do
      sign_in(user)
      visit dashboard_todos_path
    end

    it 'shows the todo' do
      expect(page).to have_content 'The pipeline failed.'
    end
  end

  context 'User has a todo regarding a design' do
    let_it_be(:target) { create(:design, issue: issue, project: project) }
    let_it_be(:note) { create(:note, project: project, note: 'I am note, hear me roar') }
    let_it_be(:todo) do
      create(
        :todo,
        :mentioned,
        user: user,
        project: project,
        target: target,
        author: author,
        note: note
      )
    end

    before do
      enable_design_management
      project.add_developer(user)
      sign_in(user)

      visit dashboard_todos_path
    end

    it 'has todo present' do
      expect(page).to have_selector('ol[data-testid="todo-item-list"] > li', count: 1)
    end
  end

  context 'User requested access' do
    shared_examples 'has todo present with access request content' do
      specify do
        sign_in(user)
        visit dashboard_todos_path

        expect(page).to have_selector('ol[data-testid="todo-item-list"] > li', count: 1)
        expect(page).to have_content "#{author.name} has requested access to #{target_type} #{target_name}"
      end
    end

    context 'when user requests access to project or group' do
      using RSpec::Parameterized::TableSyntax

      let(:project_todo) do
        create(
          :todo,
          :member_access_requested,
          user: user,
          project: project,
          target: project,
          author: author
        )
      end

      let(:group) { create(:group, :public).tap { |g| g.add_owner(user) } }
      let(:group_todo) do
        create(
          :todo,
          :member_access_requested,
          user: user,
          project: nil,
          group: group,
          target: group,
          author: author
        )
      end

      where(:target_type, :todo) do
        'project' | ref(:project_todo)
        'group'   | ref(:group_todo)
      end

      with_them do
        it_behaves_like 'has todo present with access request content' do
          let!(:target_name) { todo.target.name }
        end
      end
    end
  end

  describe 'empty states' do
    context 'when user has no todos at all (neither pending nor done)' do
      before do
        visit dashboard_todos_path
      end

      it 'shows empty state for new users' do
        within('.gl-empty-state') do
          expect(page).to have_content 'Your To-Do List shows what to work on next'
        end
      end
    end

    context 'when user has no pending todos (but some done todos)' do
      before do
        create_todo(state: :done)
        visit dashboard_todos_path
      end

      it 'shows a "well done" message on the "Pending" tab' do
        expect(page).to have_content 'Not sure where to go next?'
        expect_tab_nav
      end
    end

    context 'when user has pending todos but applied filters with no matches' do
      before do
        create_todo(state: :pending)
        visit dashboard_todos_path(author_id: user.id)
      end

      it 'shows a "no matches" message' do
        expect(page).to have_content 'Sorry, your filter produced no results'
        expect_tab_nav
      end
    end

    context 'when user has no done tasks' do
      before do
        create_todo(state: :pending)
      end

      context 'with filters applied' do
        it 'shows a "no matches" message' do
          visit dashboard_todos_path(author_id: user.id, state: :done)
          expect(page).to have_content 'Sorry, your filter produced no results'
          expect_tab_nav
        end
      end

      context 'with no filters applied' do
        it 'shows a "no done todos" message on the "Done" tab' do
          visit dashboard_todos_path(state: :done)
          expect(page).to have_content 'There are no done to-do items yet'
          expect_tab_nav
        end
      end
    end
  end

  context 'when user has pending todos' do
    let_it_be(:todo_assigned) { create(:todo, :assigned, :pending, user: user, project: project, target: issue, author: user2) }
    let_it_be(:todo_marked) { create(:todo, :marked, :pending, user: user, project: project, target: issue, author: user) }

    before do
      visit dashboard_todos_path
    end

    it 'allows to mark a pending todo as done and find it in the Done tab' do
      expect(page).to have_content 'Michael Scott assigned you.'
      expect(page).to have_content 'You added a to-do item.'
      expect(page).to have_content 'To Do 2'

      within_testid("todo-item-gid://gitlab/Todo/#{todo_assigned.id}") do
        click_on 'Mark as done'
      end
      wait_for_requests
      click_on 'Done'
      expect(page).to have_content 'Michael Scott assigned you.'
      click_on 'To Do 1'
      expect(page).not_to have_content 'Michael Scott assigned you.'
    end
  end

  describe 'sorting' do
    let_it_be(:oldest_but_most_recently_updated) { create_todo(created_at: 3.days.ago, updated_at: 3.minutes.ago, target: issue) }
    let_it_be(:middle_old_and_middle_updated) { create_todo(created_at: 2.days.ago, updated_at: 2.hours.ago, target: issue2) }
    let_it_be(:newest_but_never_updated) { create_todo(created_at: 1.day.ago, updated_at: 1.day.ago, target: issue3) }

    before do
      visit dashboard_todos_path
    end

    it 'allows to change sort order and direction' do
      # default sort is by `created_at` (desc)
      expect(page).to have_content(
        /#{newest_but_never_updated.target.title}.*#{middle_old_and_middle_updated.target.title}.*#{oldest_but_most_recently_updated.target.title}/
      )

      # change direction
      find('.sorting-direction-button').click
      expect(page).to have_content(
        /#{oldest_but_most_recently_updated.target.title}.*#{middle_old_and_middle_updated.target.title}.*#{newest_but_never_updated.target.title}/
      )

      # change order
      click_on 'Created' # to open order dropdown
      find('li', text: 'Updated').click # to change to `updated_at`
      expect(page).to have_content(
        /#{newest_but_never_updated.target.title}.*#{middle_old_and_middle_updated.target.title}.*#{oldest_but_most_recently_updated.target.title}/
      )
    end
  end

  describe 'filtering' do
    let_it_be(:self_assigned) { create_todo(author: user, target: issue) }
    let_it_be(:self_marked) { create_todo(author: user, target: issue2, action: :marked) }
    let_it_be(:other_assigned) { create_todo(author: user2, target: issue3) }

    before do
      visit dashboard_todos_path
    end

    it 'allows to filter by auther, action etc' do
      find_by_testid('filtered-search-term').click
      find('li', text: 'Author').click
      find('li', text: user.username).click
      find_by_testid('search-button').click

      expect(page).to have_content(self_assigned.target.title)
      expect(page).to have_content(self_marked.target.title)
      expect(page).not_to have_content(other_assigned.target.title)

      find_by_testid('filtered-search-term').click
      find('li', text: 'Reason').click
      find('li', text: 'Marked').click
      find_by_testid('search-button').click

      expect(page).not_to have_content(self_assigned.target.title)
      expect(page).to have_content(self_marked.target.title)
      expect(page).not_to have_content(other_assigned.target.title)

      click_on 'Clear'

      expect(page).to have_content(self_assigned.target.title)
      expect(page).to have_content(self_marked.target.title)
      expect(page).to have_content(other_assigned.target.title)
    end
  end

  describe 'reloading' do
    let_it_be(:todo1) { create_todo(author: user, target: issue) }

    before do
      visit dashboard_todos_path
    end

    context 'when user clicks the Refresh button' do
      it 'updates the list of todos' do
        todo2 = create_todo(author: user, target: issue2)
        expect(page).not_to have_content todo2.target.title
        click_on 'Refresh'
        expect(page).to have_content todo2.target.title
      end
    end

    context 'when user stops interacting with the list' do
      it 'automatically updates the list of todos' do
        click_on 'Mark as done'
        sleep 1 # Auto-reload needs 1sec of user inactivity
        expect(page).to have_content todo1.target.title # Resolved todo is still visible
        find_by_testid('filtered-search-term-input').click # Move focus away from the list
        expect(page).to have_content 'Not sure where to go next?' # Shows empty state
        expect(page).not_to have_content todo1.target.title
      end
    end
  end

  describe '"Mark all as done" button' do
    it 'does not show' do
      create_todo
      visit dashboard_todos_path
      expect(page).not_to have_content 'Mark all as done'
    end

    context 'with todos_bulk_actions feature disabled' do
      before do
        stub_feature_flags(todos_bulk_actions: false)
      end

      context 'with no pending todos' do
        it 'does not show' do
          visit dashboard_todos_path
          expect(page).not_to have_content 'Mark all as done'
        end
      end

      context 'with pending todos' do
        let_it_be(:self_assigned) { create_todo(author: user, target: issue) }
        let_it_be(:self_marked) { create_todo(author: user, target: issue2, action: :marked) }
        let_it_be(:other_assigned) { create_todo(author: user2, target: issue3) }

        context 'with no filters applied' do
          it 'marks all pending todos as done' do
            visit dashboard_todos_path
            click_on 'Mark all as done'

            expect(page).to have_content 'Not sure where to go next?'
            within('.gl-toast') do
              expect(page).to have_content 'Marked 3 to-dos as done'
              find('a.gl-toast-action', text: 'Undo').click
            end
            expect(page).to have_content 'Restored 3 to-dos'
            expect(page).to have_selector('ol[data-testid="todo-item-list"] > li', count: 3)
          end
        end

        context 'with filters applied' do
          it 'only marks the filtered todos as done' do
            visit dashboard_todos_path(author_id: user.id)
            click_on 'Mark all as done'

            expect(page).to have_content 'Sorry, your filter produced no results'
            click_on 'Clear'
            expect(page).to have_selector('ol[data-testid="todo-item-list"] > li', count: 1)
            expect(page).to have_content(other_assigned.author.name)
          end
        end
      end
    end
  end

  def create_todo(action: :assigned, state: :pending, created_at: nil, updated_at: nil, target: issue, author: user2)
    create(
      :todo,
      action,
      state: state,
      user: user,
      created_at: created_at,
      updated_at: updated_at,
      project: project,
      target: target,
      author: author
    )
  end

  def expect_tab_nav
    expect(page).to have_content(/To Do \d+ Snoozed Done All/)
  end
end
