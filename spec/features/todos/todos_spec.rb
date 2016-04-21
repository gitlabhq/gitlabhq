require 'spec_helper'

describe 'Dashboard Todos', feature: true do
  let(:user){ create(:user) }
  let(:author){ create(:user) }
  let(:project){ create(:project) }
  let(:issue){ create(:issue) }
  let(:todos_per_page){ Todo.default_per_page }
  let(:todos_total){ todos_per_page + 1 }

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
      let(:todo_total_pages){ (todos_total.to_f/todos_per_page).ceil }

      before do
        todos_total.times do
          create(:todo, :mentioned, user: user, project: project, target: issue, author: author)
        end

        login_as(user)
        visit dashboard_todos_path
      end

      it 'is paginated' do
        expect(page).to have_selector('.gl-pagination')
      end

      it 'is has the right number of pages' do
        expect(page).to have_selector('.gl-pagination .page', count: todo_total_pages)
      end

      describe 'deleting last todo from last page', js: true do
        it 'redirects to the previous page' do
          page.within('.gl-pagination') do
            click_link todo_total_pages.to_s
          end
          first('.done-todo').click
          expect(page).to have_content(Todo.last.body)
        end
      end
    end
  end
end
