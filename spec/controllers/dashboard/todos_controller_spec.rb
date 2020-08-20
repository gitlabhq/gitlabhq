# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Dashboard::TodosController do
  let(:user) { create(:user) }
  let(:author)  { create(:user) }
  let(:project) { create(:project) }
  let(:todo_service) { TodoService.new }

  before do
    sign_in(user)
    project.add_developer(user)
  end

  describe 'GET #index' do
    context 'project authorization' do
      it 'renders 404 when user does not have read access on given project' do
        unauthorized_project = create(:project, :private)

        get :index, params: { project_id: unauthorized_project.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 404 when given project does not exists' do
        get :index, params: { project_id: non_existing_record_id }

        expect(response).to have_gitlab_http_status(:not_found)
      end

      it 'renders 200 when filtering for "any project" todos' do
        get :index, params: { project_id: '' }

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'renders 200 when user has access on given project' do
        authorized_project = create(:project, :public)

        get :index, params: { project_id: authorized_project.id }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context "with render_views" do
      render_views

      it 'avoids N+1 queries', :request_store do
        merge_request = create(:merge_request, source_project: project)
        create(:todo, project: project, author: author, user: user, target: merge_request)
        create(:issue, project: project, assignees: [user])

        group = create(:group)
        group.add_owner(user)

        get :index

        control = ActiveRecord::QueryRecorder.new { get :index }

        create(:issue, project: project, assignees: [user])
        group_2 = create(:group)
        group_2.add_owner(user)
        project_2 = create(:project)
        project_2.add_developer(user)
        merge_request_2 = create(:merge_request, source_project: project_2)
        create(:todo, project: project, author: author, user: user, target: merge_request_2)

        expect { get :index }.not_to exceed_query_limit(control)
        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'group authorization' do
      it 'renders 404 when user does not have read access on given group' do
        unauthorized_group = create(:group, :private)

        get :index, params: { group_id: unauthorized_group.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it_behaves_like 'paginated collection' do
      let!(:issues) { create_list(:issue, 3, project: project, assignees: [user]) }
      let(:collection) { user.todos }

      before do
        issues.each { |issue| todo_service.new_issue(issue, user) }
        allow(Kaminari.config).to receive(:default_per_page).and_return(2)
      end

      context 'when providing no filters' do
        it 'does not perform a query to get the page count, but gets that from the user' do
          allow(controller).to receive(:current_user).and_return(user)

          expect(user).to receive(:todos_pending_count).and_call_original

          get :index, params: { page: (last_page + 1).to_param, sort: :created_asc }

          expect(response).to redirect_to(dashboard_todos_path(page: last_page, sort: :created_asc))
        end
      end

      context 'when providing filters' do
        it 'performs a query to get the correct page count' do
          allow(controller).to receive(:current_user).and_return(user)

          expect(user).not_to receive(:todos_pending_count)

          get :index, params: { page: (last_page + 1).to_param, project_id: project.id }

          expect(response).to redirect_to(dashboard_todos_path(page: last_page, project_id: project.id))
        end
      end
    end

    context 'external authorization' do
      subject { get :index }

      it_behaves_like 'disabled when using an external authorization service'
    end
  end

  describe 'PATCH #restore' do
    let(:todo) { create(:todo, :done, user: user, project: project, author: author) }

    it 'restores the todo to pending state' do
      patch :restore, params: { id: todo.id }

      expect(todo.reload).to be_pending
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({ "count" => 1, "done_count" => 0 })
    end
  end

  describe 'PATCH #bulk_restore' do
    let(:todos) { create_list(:todo, 2, :done, user: user, project: project, author: author) }

    it 'restores the todos to pending state' do
      patch :bulk_restore, params: { ids: todos.map(&:id) }

      todos.each do |todo|
        expect(todo.reload).to be_pending
      end
      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response).to eq({ 'count' => 2, 'done_count' => 0 })
    end
  end
end
