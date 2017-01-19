require 'spec_helper'

describe Dashboard::TodosController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:todo_service) { TodoService.new }

  describe 'GET #index' do
    before do
      sign_in(user)
      project.team << [user, :developer]
    end

    context 'when using pagination' do
      let(:last_page) { user.todos.page.total_pages }
      let!(:issues) { create_list(:issue, 2, project: project, assignee: user) }

      before do
        issues.each { |issue| todo_service.new_issue(issue, user) }
        allow(Kaminari.config).to receive(:default_per_page).and_return(1)
      end

      it 'redirects to last_page if page number is larger than number of pages' do
        get :index, page: (last_page + 1).to_param

        expect(response).to redirect_to(dashboard_todos_path(page: last_page))
      end

      it 'redirects to correspondent page' do
        get :index, page: last_page

        expect(assigns(:todos).current_page).to eq(last_page)
        expect(response).to have_http_status(200)
      end
    end
  end
end
