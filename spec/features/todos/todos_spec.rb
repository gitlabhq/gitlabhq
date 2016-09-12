require 'spec_helper'

describe 'Dashboard Todos', feature: true do
  let(:user)    { create(:user) }
  let(:author)  { create(:user) }
  let(:project) { create(:project, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }
  let(:issue)   { create(:issue) }

  describe 'GET /dashboard/todos' do
    context 'User does not have todos' do
      before do
        login_as(user)
        visit dashboard_todos_path
      end
      it 'shows "All done" message' do
        expect(page).to have_content "You're all done!"
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

      describe 'deleting the todo' do
        before do
          first('.done-todo').click
        end

        it 'is removed from the list' do
          expect(page).not_to have_selector('.todos-list .todo')
        end

        it 'shows "All done" message' do
          expect(page).to have_content("You're all done!")
        end
      end

      context 'todo is stale on the page' do
        before do
          todos = TodosFinder.new(user, state: :pending).execute
          TodoService.new.mark_todos_as_done(todos, user)
        end

        describe 'deleting the todo' do
          before do
            first('.done-todo').click
          end

          it 'is removed from the list' do
            expect(page).not_to have_selector('.todos-list .todo')
          end

          it 'shows "All done" message' do
            expect(page).to have_content("You're all done!")
          end
        end
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

      describe 'completing last todo from last page', js: true do
        it 'redirects to the previous page' do
          visit dashboard_todos_path(page: 2)
          expect(page).to have_css("#todo_#{Todo.last.id}")

          click_link('Done')

          expect(current_path).to eq dashboard_todos_path
          expect(page).to have_css("#todo_#{Todo.first.id}")
        end
      end

      describe 'mark all as done', js: true do
        before do
          visit dashboard_todos_path
          click_link('Mark all as done')
        end

        it 'shows "All done" message!' do
          within('.todos-pending-count') { expect(page).to have_content '0' }
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
        expect(page).to have_content "You're all done!"
      end
    end
  end
end
