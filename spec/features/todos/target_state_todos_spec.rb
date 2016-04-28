require 'rails_helper'

describe 'Todos > Target State Labels' do
  let(:user)          { create(:user) }
  let(:author)        { create(:user) }
  let(:project)       { create(:project) }
  let(:issue_open)    { create(:issue) }
  let(:issue_closed)  { create(:issue, state: 'closed') }
  let(:mr_open)       { create(:merge_request, :simple, author: user) }
  let(:mr_merged)     { create(:merge_request, :simple, author: user, state: 'merged') }
  let(:mr_closed)     { create(:merge_request, :simple, author: user, state: 'closed') }

  describe 'GET /dashboard/todos' do
    context 'On a todo for a Closed Issue' do
      before do
        create(:todo, :mentioned, user: user, project: project, target: issue_closed, author: author)
        login_as user
        visit dashboard_todos_path
      end

      it 'has closed label' do
        page.within '.todos-list' do
          expect(page).to have_content('Closed')
        end
      end
    end

    context 'On a todo for a Open Issue' do
      before do
        create(:todo, :mentioned, user: user, project: project, target: issue_open, author: author)
        login_as user
        visit dashboard_todos_path
      end

      it 'does not have a open label' do
        page.within '.todos-list' do
          expect(page).not_to have_content('Open')
        end
      end
    end

    context 'On a todo for a merged Merge Request' do
      before do
        create(:todo, :mentioned, user: user, project: project, target: mr_merged, author: author)
        login_as user
        visit dashboard_todos_path
      end

      it 'has merged label' do
        page.within '.todos-list' do
          expect(page).to have_content('Merged')
        end
      end
    end

    context 'On a todo for a closed Merge Request' do
      before do
        create(:todo, :mentioned, user: user, project: project, target: mr_closed, author: author)
        login_as user
        visit dashboard_todos_path
      end

      it 'has closed label' do
        page.within '.todos-list' do
          expect(page).to have_content('Closed')
        end
      end
    end

    context 'On a todo for a open Merge Request' do
      before do
        create(:todo, :mentioned, user: user, project: project, target: mr_open, author: author)
        login_as user
        visit dashboard_todos_path
      end

      it 'does not have a open label' do
        page.within '.todos-list' do
          expect(page).not_to have_content('Open')
        end
      end
    end
  end
end
