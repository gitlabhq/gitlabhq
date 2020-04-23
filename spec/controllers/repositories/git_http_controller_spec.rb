# frozen_string_literal: true

require 'spec_helper'

describe Repositories::GitHttpController do
  include GitHttpHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :public, :repository) }
  let_it_be(:project_snippet) { create(:project_snippet, :public, :repository, project: project) }

  let(:namespace_id) { project.namespace.to_param }
  let(:repository_id) { project.path + '.git' }
  let(:container_params) do
    {
      namespace_id: namespace_id,
      repository_id: repository_id
    }
  end
  let(:params) { container_params }

  describe 'HEAD #info_refs' do
    it 'returns 403' do
      head :info_refs, params: params

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  shared_examples 'info_refs behavior' do
    describe 'GET #info_refs' do
      let(:params) { container_params.merge(service: 'git-upload-pack') }

      it 'returns 401 for unauthenticated requests to public repositories when http protocol is disabled' do
        stub_application_setting(enabled_git_access_protocol: 'ssh')
        allow(controller).to receive(:basic_auth_provided?).and_call_original

        expect(controller).to receive(:http_download_allowed?).and_call_original

        get :info_refs, params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      context 'with authorized user' do
        before do
          request.headers.merge! auth_env(user.username, user.password, nil)
        end

        it 'returns 200' do
          get :info_refs, params: params

          expect(response).to have_gitlab_http_status(:ok)
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

          expect(response).to have_gitlab_http_status(:service_unavailable)
        end

        it 'returns 503 with timeout error' do
          allow(controller).to receive(:access_check).and_raise(Gitlab::GitAccess::TimeoutError)

          get :info_refs, params: params

          expect(response).to have_gitlab_http_status(:service_unavailable)
          expect(response.body).to eq 'Gitlab::GitAccess::TimeoutError'
        end
      end
    end
  end

  shared_examples 'git_upload_pack behavior' do |expected|
    describe 'POST #git_upload_pack' do
      before do
        allow(controller).to receive(:authenticate_user).and_return(true)
        allow(controller).to receive(:verify_workhorse_api!).and_return(true)
        allow(controller).to receive(:access_check).and_return(nil)
      end

      def send_request
        post :git_upload_pack, params: params
      end

      context 'on a read-only instance' do
        before do
          allow(Gitlab::Database).to receive(:read_only?).and_return(true)
        end

        it 'does not update project statistics' do
          expect(ProjectDailyStatisticsWorker).not_to receive(:perform_async)

          send_request
        end
      end

      if expected
        context 'when project_statistics_sync feature flag is disabled' do
          before do
            stub_feature_flags(project_statistics_sync: false)
          end

          it 'updates project statistics async' do
            expect(ProjectDailyStatisticsWorker).to receive(:perform_async)

            send_request
          end
        end

        it 'updates project statistics sync' do
          expect { send_request }.to change {
            Projects::DailyStatisticsFinder.new(project).total_fetch_count
          }.from(0).to(1)
        end
      else
        context 'when project_statistics_sync feature flag is disabled' do
          before do
            stub_feature_flags(project_statistics_sync: false)
          end

          it 'does not update project statistics' do
            expect(ProjectDailyStatisticsWorker).not_to receive(:perform_async)

            send_request
          end
        end

        it 'does not update project statistics' do
          expect { send_request }.not_to change {
            Projects::DailyStatisticsFinder.new(project).total_fetch_count
          }.from(0)
        end
      end
    end
  end

  shared_examples 'access checker class' do
    let(:params) { container_params.merge(service: 'git-upload-pack') }

    it 'calls the right access class checker with the right object' do
      allow(controller).to receive(:verify_workhorse_api!).and_return(true)

      access_double = double
      expect(expected_class).to receive(:new).with(anything, expected_object, 'http', anything).and_return(access_double)
      allow(access_double).to receive(:check).and_return(false)

      get :info_refs, params: params
    end
  end

  context 'when repository container is a project' do
    it_behaves_like 'info_refs behavior' do
      let(:user) { project.owner }
    end
    it_behaves_like 'git_upload_pack behavior', true
    it_behaves_like 'access checker class' do
      let(:expected_class) { Gitlab::GitAccess }
      let(:expected_object) { project }
    end
  end

  context 'when repository container is a personal snippet' do
    let(:namespace_id) { 'snippets' }
    let(:repository_id) { personal_snippet.to_param + '.git' }

    it_behaves_like 'info_refs behavior' do
      let(:user) { personal_snippet.author }
    end
    it_behaves_like 'git_upload_pack behavior', false
    it_behaves_like 'access checker class' do
      let(:expected_class) { Gitlab::GitAccessSnippet }
      let(:expected_object) { personal_snippet }
    end
  end

  context 'when repository container is a project snippet' do
    let(:namespace_id) { project.full_path + '/snippets' }
    let(:repository_id) { project_snippet.to_param + '.git' }

    it_behaves_like 'info_refs behavior' do
      let(:user) { project_snippet.author }
    end
    it_behaves_like 'git_upload_pack behavior', false
    it_behaves_like 'access checker class' do
      let(:expected_class) { Gitlab::GitAccessSnippet }
      let(:expected_object) { project_snippet }
    end
  end
end
