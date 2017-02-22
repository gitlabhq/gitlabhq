require 'spec_helper'

describe 'Dashboard Todos', feature: true do
  include WaitForAjax

  let(:user)    { create(:user) }
  let(:author)  { create(:user) }
  let(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:issue)   { create(:issue, due_date: Date.today) }

  describe 'GET /dashboard/todos' do
    context 'User does not have todos' do
      before do
        login_as(user)
        visit dashboard_todos_path
      end
      it 'shows "All done" message' do
        expect(page).to have_content "Todos let you see what you should do next."
      end
    end

    context 'User has a todo', js: true do
      before do
        create(:todo, :mentioned, user: user, project: project, target: issue, author: author)
        login_as(user)
        visit dashboard_todos_path
      end

      it 'has todo present' do
        expect(page).to have_selector('.todos-list .todo', count: 1)
      end

      it 'shows due date as today' do
        page.within first('.todo') do
          expect(page).to have_content 'Due today'
        end
      end

      shared_examples 'deleting the todo' do
        before do
          first('.js-done-todo').click
        end

        it 'is marked as done-reversible in the list' do
          expect(page).to have_selector('.todos-list .todo.todo-pending.done-reversible')
        end

        it 'shows Undo button' do
          expect(page).to have_selector('.js-undo-todo', visible: true)
          expect(page).to have_selector('.js-done-todo', visible: false)
        end

        it 'updates todo count' do
          expect(page).to have_content 'To do 0'
          expect(page).to have_content 'Done 1'
        end

        it 'has not "All done" message' do
          expect(page).not_to have_selector('.todos-all-done')
        end
      end

      shared_examples 'deleting and restoring the todo' do
        before do
          first('.js-done-todo').click
          wait_for_ajax
          first('.js-undo-todo').click
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
          expect(page).to have_content 'To do 1'
          expect(page).to have_content 'Done 0'
        end
      end

      it_behaves_like 'deleting the todo'
      it_behaves_like 'deleting and restoring the todo'

      context 'todo is stale on the page' do
        before do
          todos = TodosFinder.new(user, state: :pending).execute
          TodoService.new.mark_todos_as_done(todos, user)
        end

        it_behaves_like 'deleting the todo'
        it_behaves_like 'deleting and restoring the todo'
      end
    end

    context 'User has Todos with labels spanning multiple projects' do
      before do
        label1 = create(:label, project: project)
        note1 = create(:note_on_issue, note: "Hello #{label1.to_reference(format: :name)}", noteable_id: issue.id, noteable_type: 'Issue', project: issue.project)
        create(:todo, :mentioned, project: project, target: issue, user: user, note_id: note1.id)

        project2 = create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        label2 = create(:label, project: project2)
        issue2 = create(:issue, project: project2)
        note2 = create(:note_on_issue, note: "Test #{label2.to_reference(format: :name)}", noteable_id: issue2.id, noteable_type: 'Issue', project: project2)
        create(:todo, :mentioned, project: project2, target: issue2, user: user, note_id: note2.id)

        login_as(user)
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

        login_as(user)
      end

      it 'is paginated' do
        visit dashboard_todos_path

        expect(page).to have_selector('.gl-pagination')
      end

      it 'is has the right number of pages' do
        visit dashboard_todos_path

        expect(page).to have_selector('.gl-pagination .page', count: 2)
      end

      describe 'mark all as done', js: true do
        before do
          visit dashboard_todos_path
          click_link('Mark all as done')
        end

        it 'shows "All done" message!' do
          expect(page).to have_content 'To do 0'
          expect(page).to have_content "You're all done!"
          expect(page).not_to have_selector('.gl-pagination')
        end
      end
    end

    context 'User has a Todo in a project pending deletion' do
      before do
        deleted_project = create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC, pending_delete: true)
        create(:todo, :mentioned, user: user, project: deleted_project, target: issue, author: author)
        create(:todo, :mentioned, user: user, project: deleted_project, target: issue, author: author, state: :done)
        login_as(user)
        visit dashboard_todos_path
      end

      it 'shows "All done" message' do
        within('.todos-pending-count') { expect(page).to have_content '0' }
        expect(page).to have_content 'To do 0'
        expect(page).to have_content 'Done 0'
        expect(page).to have_selector('.todos-all-done', count: 1)
      end
    end

    context 'User have large number of todos' do
      before do
        create_list(:todo, 101, :mentioned, user: user, project: project, target: issue, author: author)

        login_as(user)
        visit dashboard_todos_path
      end

      it 'shows 99+ for count >= 100 in notification' do
        expect(page).to have_selector('.todos-pending-count', text: '99+')
      end

      it 'shows exact number in To do tab' do
        expect(page).to have_selector('.todos-pending .badge', text: '101')
      end

      it 'shows exact number for count < 100' do
        3.times { first('.js-done-todo').click }

        expect(page).to have_selector('.todos-pending-count', text: '98')
      end
    end

    context 'User has a Build Failed todo' do
      let!(:todo) { create(:todo, :build_failed, user: user, project: project, author: author) }

      before do
        login_as user
        visit dashboard_todos_path
      end

      it 'shows the todo' do
        expect(page).to have_content 'The build failed for merge request'
      end

      it 'links to the pipelines for the merge request' do
        href = pipelines_namespace_project_merge_request_path(project.namespace, project, todo.target)

        expect(page).to have_link "merge request #{todo.target.to_reference(full: true)}", href
      end
    end
  end
end
