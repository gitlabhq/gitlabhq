# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard Todos', :js, feature_category: :team_planning do
  include DesignManagementTestHelpers

  let_it_be(:user) { create(:user, username: 'john') }
  let_it_be(:user2) { create(:user, username: 'diane') }
  let_it_be(:user3) { create(:user) }
  let_it_be(:author) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue) { create(:issue, project: project, due_date: Date.today, title: "Fix bug") }

  before_all do
    project.add_developer(user)
  end

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_todos_path, :todos

  context 'User does not have todos' do
    before do
      sign_in(user)
      visit dashboard_todos_path
    end

    it 'shows empty state but not the page title' do
      expect(page).to have_content 'Your To-Do List shows what to work on next'
      expect(page).to have_selector('.gl-empty-state')
      expect(page).not_to have_selector('.page-title-holder')
    end

    context 'when user was assigned to an issue and marked it as done' do
      before do
        sign_in(user)
      end

      it 'shows "Not sure where to go next?" message' do
        create(:todo, :assigned, :done, user: user, project: project, target: issue, author: user2)
        visit dashboard_todos_path

        expect(page).to have_content 'Not sure where to go next? Take a look at your assigned issues or merge requests.'
      end
    end
  end

  context 'when the todo references a merge request' do
    let(:referenced_mr) { create(:merge_request, source_project: project) }
    let(:note) { create(:note, project: project, note: "Check out #{referenced_mr.to_reference}", noteable: create(:issue, project: project)) }
    let!(:todo) { create(:todo, :mentioned, user: user, project: project, author: author, note: note, target: note.noteable) }

    before do
      sign_in(user)
      visit dashboard_todos_path
    end

    it 'renders the mr reference' do
      expect(page).to have_content(referenced_mr.to_reference)
    end
  end

  context 'user has an unauthorized todo' do
    before do
      sign_in(user)
    end

    it 'does not render the todo' do
      unauthorized_issue = create(:issue)
      create(:todo, :mentioned, user: user, project: unauthorized_issue.project, target: unauthorized_issue, author: author)
      create(:todo, :mentioned, user: user, project: project, target: issue, author: author)

      visit dashboard_todos_path

      expect(page).to have_selector('.todos-list .todo', count: 1)
    end
  end

  context 'User has a todo' do
    let_it_be(:user_todo) { create(:todo, :mentioned, user: user, project: project, target: issue, author: author) }

    before do
      sign_in(user)

      visit dashboard_todos_path
    end

    it 'has todo present' do
      expect(page).to have_selector('.todos-list .todo', count: 1)
    end

    it 'shows due date as today' do
      within first('.todo') do
        expect(page).to have_content 'Due today'
      end
    end

    shared_examples 'deleting the todo' do
      before do
        within first('.todo') do
          find_by_testid('check-icon').click
        end
      end

      it 'is marked as done-reversible in the list' do
        expect(page).to have_selector('.todos-list .todo.todo-pending.done-reversible')
      end

      it 'shows Undo button' do
        expect(page).to have_selector('.js-undo-todo', visible: true)
        expect(page).to have_selector('.js-done-todo', visible: false)
      end

      it 'updates todo count' do
        expect(page).to have_content 'To Do 0'
        expect(page).to have_content 'Done 1'
      end

      it 'has not "All done" message' do
        expect(page).not_to have_selector('.empty-state')
      end
    end

    shared_examples 'deleting and restoring the todo' do
      before do
        within first('.todo') do
          find_by_testid('check-icon').click
          wait_for_requests
          find_by_testid('redo-icon').click
        end
      end

      it 'is marked back as pending in the list' do
        expect(page).not_to have_selector('.todos-list .todo.todo-pending.done-reversible')
        expect(page).to have_selector('.todos-list .todo.todo-pending')
      end

      it 'shows Done button' do
        expect(page).to have_selector('.js-undo-todo', visible: false)
        expect(page).to have_selector('.js-done-todo', visible: true)
      end

      it 'updates todo count' do
        expect(page).to have_content 'To Do 1'
        expect(page).to have_content 'Done 0'
      end
    end

    it_behaves_like 'deleting the todo'
    it_behaves_like 'deleting and restoring the todo'

    context 'todo is stale on the page' do
      before do
        todos = TodosFinder.new(user, state: :pending).execute
        TodoService.new.resolve_todos(todos, user)
      end

      it_behaves_like 'deleting the todo'
      it_behaves_like 'deleting and restoring the todo'
    end

    context 'when todo has a note' do
      let(:note) { create(:note, project: project, note: "Check out stuff", noteable: create(:issue, project: project)) }
      let!(:todo) { create(:todo, :mentioned, user: user, project: project, author: author, note: note, target: note.noteable) }

      before do
        sign_in(user)
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
    before do
      sign_in(user)
    end

    context 'issue assigned todo' do
      before do
        create(:todo, :assigned, user: user, project: project, target: issue, author: user)
        visit dashboard_todos_path
      end

      it 'shows issue assigned to yourself message' do
        page.within('.js-todos-all') do
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
        page.within('.js-todos-all') do
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
        page.within('.js-todos-all') do
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
        page.within('.js-todos-all') do
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
        page.within('.js-todos-all') do
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
        page.within('.js-todos-all') do
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
        page.within('.js-todos-all') do
          expect(page).to have_content("Fix bug · #{project.namespace.owner_name} / #{project.name} #{issue.to_reference}")
          expect(page).to have_content("Could not merge.")
        end
      end
    end
  end

  context 'User has done todos' do
    before do
      create(:todo, :mentioned, :done, user: user, project: project, target: issue, author: author)
      sign_in(user)
      visit dashboard_todos_path(state: :done)
    end

    it 'has the done todo present' do
      expect(page).to have_selector('.todos-list .todo.todo-done', count: 1)
    end

    describe 'restoring the todo' do
      before do
        within first('.todo') do
          find_by_testid('redo-icon').click
        end
      end

      it 'is removed from the list' do
        expect(page).not_to have_selector('.todos-list .todo.todo-done')
      end

      it 'updates todo count' do
        expect(page).to have_content 'To Do 1'
        expect(page).to have_content 'Done 0'
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

      gitlab_sign_in(user)
      visit dashboard_todos_path
    end

    it 'shows page with two Todos' do
      expect(page).to have_selector('.todos-list .todo', count: 2)
    end
  end

  context 'User has multiple pages of Todos' do
    before do
      allow(Todo).to receive(:default_per_page).and_return(1)

      # Create just enough records to cause us to paginate
      create_list(:todo, 2, :mentioned, user: user, project: project, target: issue, author: author)

      sign_in(user)
    end

    it 'is paginated' do
      visit dashboard_todos_path

      expect(page).to have_selector('.gl-pagination')
    end

    it 'is has the right number of pages' do
      visit dashboard_todos_path

      expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
    end

    describe 'mark all as done' do
      before do
        visit dashboard_todos_path
        find('.js-todos-mark-all').click
      end

      it 'shows "All done" message!' do
        expect(page).to have_content 'To Do 0'
        expect(page).to have_content "You're all done!"
        expect(page).not_to have_selector('.gl-pagination')
      end

      it 'shows "Undo mark all as done" button' do
        expect(page).to have_selector('.js-todos-mark-all', visible: false)
        expect(page).to have_selector('.js-todos-undo-all', visible: true)
      end
    end

    describe 'undo mark all as done' do
      before do
        visit dashboard_todos_path
      end

      it 'shows the restored todo list' do
        mark_all_and_undo

        expect(page).to have_selector('.todos-list .todo', count: 1)
        expect(page).to have_selector('.gl-pagination')
        expect(page).not_to have_content "You're all done!"
      end

      it 'updates todo count' do
        mark_all_and_undo

        expect(page).to have_content 'To Do 2'
        expect(page).to have_content 'Done 0'
      end

      it 'shows "Mark all as done" button' do
        mark_all_and_undo

        expect(page).to have_selector('.js-todos-mark-all', visible: true)
        expect(page).to have_selector('.js-todos-undo-all', visible: false)
      end

      context 'User has deleted a todo' do
        before do
          within first('.todo') do
            find_by_testid('check-icon').click
          end
        end

        it 'shows the restored todo list with the deleted todo' do
          mark_all_and_undo

          expect(page).to have_selector('.todos-list .todo.todo-pending', count: 1)
        end
      end

      def mark_all_and_undo
        find('.js-todos-mark-all').click
        wait_for_requests
        find('.js-todos-undo-all').click
        wait_for_requests
      end
    end

    describe 'shows a count of todos' do
      before do
        allow(Todo).to receive(:default_per_page).and_return(1)
        create_list(:todo, 2, :mentioned, user: user3, project: project, target: issue, author: author, state: :pending)
        create_list(:todo, 2, :mentioned, user: user3, project: project, target: issue, author: author, state: :done)
        sign_in(user3)
      end

      it 'displays a count of all pending todos' do
        visit dashboard_todos_path
        expect(find('.js-todos-pending')).to have_content('2')
      end

      it 'displays a count of all done todos' do
        visit dashboard_todos_path(state: 'done')
        expect(find('.js-todos-done')).to have_content('2')
      end
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
      expect(page).to have_selector('.todos-list .todo', count: 1)
    end
  end

  context 'User requested access' do
    shared_examples 'has todo present with access request content' do
      specify do
        sign_in(user)
        visit dashboard_todos_path

        expect(page).to have_selector('.todos-list .todo', count: 1)
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
end
