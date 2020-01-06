# frozen_string_literal: true

require 'spec_helper'

describe Projects::GitHttpController do
  include GitHttpHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let(:project_params) do
    {
      namespace_id: project.namespace.to_param,
      project_id: project.path + '.git'
    }
  end
  let(:params) { project_params }

  describe 'HEAD #info_refs' do
    it 'returns 403' do
      head :info_refs, params: { namespace_id: project.namespace.to_param, project_id: project.path + '.git' }

      expect(response.status).to eq(403)
    end
  end

  describe 'GET #info_refs' do
    let(:params) { project_params.merge(service: 'git-upload-pack') }

    it 'returns 401 for unauthenticated requests to public repositories when http protocol is disabled' do
      stub_application_setting(enabled_git_access_protocol: 'ssh')

      get :info_refs, params: params

      expect(response.status).to eq(401)
    end

    context 'with authorized user' do
      let(:user) { project.owner }

      before do
        request.headers.merge! auth_env(user.username, user.password, nil)
      end

      it 'returns 200' do
        get :info_refs, params: params

        expect(response.status).to eq(200)
      end

      it 'updates the user activity' do
        expect_next_instance_of(Users::ActivityService) do |activity_service|
          expect(activity_service).to receive(:execute)
        end

        get :info_refs, params: params
      end
    end

    context 'with exceptions' do
      before do
        allow(controller).to receive(:verify_workhorse_api!).and_return(true)
      end

      it 'returns 503 with GRPC Unavailable' do
        allow(controller).to receive(:access_check).and_raise(GRPC::Unavailable)

        get :info_refs, params: params

        expect(response.status).to eq(503)
      end

      it 'returns 503 with timeout error' do
        allow(controller).to receive(:access_check).and_raise(Gitlab::GitAccess::TimeoutError)

        get :info_refs, params: params

        expect(response.status).to eq(503)
        expect(response.body).to eq 'Gitlab::GitAccess::TimeoutError'
      end
    end
  end

  describe 'POST #git_upload_pack' do
    before do
      allow(controller).to receive(:authenticate_user).and_return(true)
      allow(controller).to receive(:verify_workhorse_api!).and_return(true)
      allow(controller).to receive(:access_check).and_return(nil)
    end

    after do
      post :git_upload_pack, params: params
    end

    it 'updates project statistics' do
      expect(ProjectDailyStatisticsWorker).to receive(:perform_async)
    end
  end
end
