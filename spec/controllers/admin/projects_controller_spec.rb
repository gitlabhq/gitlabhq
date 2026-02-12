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

  describe '#project_identifier_params' do
    it 'permits only namespace_id and id parameters' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          namespace_id: 'namespace',
          id: 'project',
          new_namespace_id: 123,
          extra_param: 'value',
          malicious: 'data'
        )
      )

      result = controller_instance.send(:project_identifier_params)

      expect(result.keys).to contain_exactly('namespace_id', 'id')
      expect(result[:namespace_id]).to eq('namespace')
      expect(result[:id]).to eq('project')
      expect(result[:new_namespace_id]).to be_nil
      expect(result[:extra_param]).to be_nil
      expect(result[:malicious]).to be_nil
      expect(result.permitted?).to be true
    end
  end

  describe '#transfer_params' do
    it 'permits only new_namespace_id parameter' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          new_namespace_id: 123,
          namespace_id: 'namespace',
          id: 'project',
          extra_param: 'value',
          malicious: 'data'
        )
      )

      result = controller_instance.send(:transfer_params)

      expect(result.keys).to contain_exactly('new_namespace_id')
      expect(result[:new_namespace_id]).to eq(123)
      expect(result[:namespace_id]).to be_nil
      expect(result[:id]).to be_nil
      expect(result[:extra_param]).to be_nil
      expect(result[:malicious]).to be_nil
      expect(result.permitted?).to be true
    end
  end

  describe '#page_params' do
    it 'permits only pagination parameters' do
      controller_instance = described_class.new
      allow(controller_instance).to receive(:params).and_return(
        ActionController::Parameters.new(
          group_members_page: 1,
          project_members_page: 2,
          namespace_id: 'namespace',
          extra_param: 'value',
          malicious: 'data'
        )
      )

      result = controller_instance.send(:page_params)

      expect(result.keys).to contain_exactly('group_members_page', 'project_members_page')
      expect(result[:group_members_page]).to eq(1)
      expect(result[:project_members_page]).to eq(2)
      expect(result[:namespace_id]).to be_nil
      expect(result[:extra_param]).to be_nil
      expect(result[:malicious]).to be_nil
      expect(result.permitted?).to be true
    end
  end
end
