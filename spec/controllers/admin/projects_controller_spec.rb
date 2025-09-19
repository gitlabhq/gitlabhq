# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::ProjectsController, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project, :public) }

  before do
    sign_in(create(:admin))
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
