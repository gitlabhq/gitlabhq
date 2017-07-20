require 'spec_helper'

describe Dashboard::TodosController do
  let(:user) { create(:user) }
  let(:author)  { create(:user) }
  let(:project) { create(:empty_project) }
  let(:todo_service) { TodoService.new }

  before do
    sign_in(user)
    project.team << [user, :developer]
  end

  describe 'GET #index' do
    context 'project authorization' do
      it 'renders 404 when user does not have read access on given project' do
        unauthorized_project = create(:empty_project, :private)

        get :index, project_id: unauthorized_project.id

        expect(response).to have_http_status(404)
      end

      it 'renders 404 when given project does not exists' do
        get :index, project_id: 999

        expect(response).to have_http_status(404)
      end

      it 'renders 200 when filtering for "any project" todos' do
        get :index, project_id: ''

        expect(response).to have_http_status(200)
      end

      it 'renders 200 when user has access on given project' do
        authorized_project = create(:empty_project, :public)

        get :index, project_id: authorized_project.id

        expect(response).to have_http_status(200)
      end
    end

    context 'when using pagination' do
      let(:last_page) { user.todos.page.total_pages }
      let!(:issues) { create_list(:issue, 2, project: project, assignees: [user]) }

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

      it 'does not redirect to external sites when provided a host field' do
        external_host = "www.example.com"
        get :index, page: (last_page + 1).to_param, host: external_host

        expect(response).to redirect_to(dashboard_todos_path(page: last_page))
      end
    end
  end

  describe 'PATCH #restore' do
    let(:todo) { create(:todo, :done, user: user, project: project, author: author) }

    it 'restores the todo to pending state' do
      patch :restore, id: todo.id

      expect(todo.reload).to be_pending
      expect(response).to have_http_status(200)
      expect(json_response).to eq({ "count" => "1", "done_count" => "0" })
    end
  end

  describe 'PATCH #bulk_restore' do
    let(:todos) { create_list(:todo, 2, :done, user: user, project: project, author: author) }

    it 'restores the todos to pending state' do
      patch :bulk_restore, ids: todos.map(&:id)

      todos.each do |todo|
        expect(todo.reload).to be_pending
      end
      expect(response).to have_http_status(200)
      expect(json_response).to eq({ 'count' => '2', 'done_count' => '0' })
    end
  end
end
