require 'spec_helper'

describe 'Dashboard Todos', feature: true do
  let(:user)    { create(:user) }
  let(:author)  { create(:user) }
  let(:project) { create(:project) }
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

      it 'todo is present' do
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
          expect(page).to have_content(Todo.first.body)

          click_link('Done')

          expect(current_path).to eq dashboard_todos_path
          expect(page).to have_content(Todo.last.body)
        end
      end
    end
  end
end
