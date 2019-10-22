# frozen_string_literal: true

require 'spec_helper'

describe Projects::GitHttpController do
  describe 'HEAD #info_refs' do
    it 'returns 403' do
      project = create(:project, :public, :repository)

      head :info_refs, params: { namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

      expect(response.status).to eq(403)
    end
  end

  describe 'GET #info_refs' do
    it 'returns 401 for unauthenticated requests to public repositories when http protocol is disabled' do
      stub_application_setting(enabled_git_access_protocol: 'ssh')
      project = create(:project, :public, :repository)

      get :info_refs, params: { service: 'git-upload-pack', namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

      expect(response.status).to eq(401)
    end

    context 'with exceptions' do
      let(:project) { create(:project, :public, :repository) }

      before do
        allow(controller).to receive(:verify_workhorse_api!).and_return(true)
      end

      it 'returns 503 with GRPC Unavailable' do
        allow(controller).to receive(:access_check).and_raise(GRPC::Unavailable)

        get :info_refs, params: { service: 'git-upload-pack', namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

        expect(response.status).to eq(503)
      end

      it 'returns 503 with timeout error' do
        allow(controller).to receive(:access_check).and_raise(Gitlab::GitAccess::TimeoutError)

        get :info_refs, params: { service: 'git-upload-pack', namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

        expect(response.status).to eq(503)
        expect(response.body).to eq 'Gitlab::GitAccess::TimeoutError'
      end
    end
  end
end
