# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ProjectsController, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :public) }

  before do
    sign_in(create(:admin))
  end

  describe 'GET /projects' do
    render_views

    it 'retrieves the project for the given visibility level' do
      get :index, params: { visibility_level: [Gitlab::VisibilityLevel::PUBLIC] }

      expect(response.body).to match(project.name)
    end

    it 'does not retrieve the project' do
      get :index, params: { visibility_level: [Gitlab::VisibilityLevel::INTERNAL] }

      expect(response.body).not_to match(project.name)
    end

    it 'retrieves archived and non archived corrupted projects when last_repository_check_failed is true' do
      archived_corrupted_project = create(:project, :public, :archived, :last_repository_check_failed, name: 'CorruptedArchived', path: 'A')
      corrupted_project = create(:project, :public, :last_repository_check_failed, name: 'CorruptedOnly', path: 'C')

      get :index, params: { last_repository_check_failed: true }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).not_to match(project.name)
      expect(response.body).to match(archived_corrupted_project.name)
      expect(response.body).to match(corrupted_project.name)
    end

    it 'does not respond with projects pending deletion' do
      pending_delete_project = create(:project, pending_delete: true)

      get :index

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).not_to match(pending_delete_project.name)
      expect(response.body).to match(project.name)
    end

    it 'does not have N+1 queries', :use_clean_rails_memory_store_caching, :request_store do
      get :index

      control = ActiveRecord::QueryRecorder.new { get :index }

      create(:project)

      expect { get :index }.not_to exceed_query_limit(control)
    end
  end

  describe 'GET /projects.json' do
    render_views

    before do
      get :index, format: :json
    end

    it { is_expected.to respond_with(:success) }
  end

  describe 'GET /projects/:id' do
    render_views

    it 'renders show page' do
      get :show, params: { namespace_id: project.namespace.path, id: project.path }

      expect(response).to have_gitlab_http_status(:ok)
      expect(response.body).to match(project.name)
    end
  end

  describe 'PUT /projects/transfer/:id' do
    let_it_be(:project, reload: true) { create(:project) }
    let_it_be(:new_namespace) { create(:namespace) }

    it 'updates namespace' do
      put :transfer, params: { namespace_id: project.namespace.path, new_namespace_id: new_namespace.id, id: project.path }

      project.reload

      expect(project.namespace).to eq(new_namespace)
      expect(response).to have_gitlab_http_status(:redirect)
      expect(response).to redirect_to(admin_project_path(project))
    end

    context 'when project transfer fails' do
      it 'flashes error' do
        old_namespace = project.namespace

        put :transfer, params: { namespace_id: old_namespace.path, new_namespace_id: nil, id: project.path }

        project.reload

        expect(project.namespace).to eq(old_namespace)
        expect(response).to have_gitlab_http_status(:redirect)
        expect(response).to redirect_to(admin_project_path(project))
        expect(flash[:alert]).to eq s_('TransferProject|Please select a new namespace for your project.')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'redirects to the admin projects path and displays the flash toast' do
      delete :destroy, params: { namespace_id: project.namespace, id: project }

      expect(flash[:toast]).to eq(format(_("Project '%{project_name}' is being deleted."), project_name: project.full_name))
      expect(response).to redirect_to(admin_projects_path)
    end
  end
end
