# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController do
  include GitHttpHelpers

  let_it_be(:project) { create(:project, :public, :repository) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :public, :repository) }
  let_it_be(:project_snippet) { create(:project_snippet, :public, :repository, project: project) }

  shared_examples Repositories::GitHttpController do
    let(:repository_path) { "#{container.full_path}.git" }
    let(:params) { { repository_path: repository_path } }

    describe 'HEAD #info_refs' do
      it 'returns 403' do
        head :info_refs, params: params

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end

    describe 'GET #info_refs' do
      let(:params) { super().merge(service: 'git-upload-pack') }

      it 'returns 401 for unauthenticated requests to public repositories when http protocol is disabled' do
        stub_application_setting(enabled_git_access_protocol: 'ssh')
        allow(controller).to receive(:basic_auth_provided?).and_call_original

        expect(controller).to receive(:http_download_allowed?).and_call_original

        get :info_refs, params: params

        expect(response).to have_gitlab_http_status(:unauthorized)
      end

      it 'calls the right access checker class with the right object' do
        allow(controller).to receive(:verify_workhorse_api!).and_return(true)

        access_double = double
        options = {
          authentication_abilities: [:download_code],
          repository_path: repository_path,
          redirected_path: nil,
          auth_result_type: :none
        }

        expect(access_checker_class).to receive(:new)
          .with(nil, container, 'http', hash_including(options))
          .and_return(access_double)

        allow(access_double).to receive(:check).and_return(false)

        get :info_refs, params: params
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

        include_context 'parsed logs' do
          it 'adds user info to the logs' do
            get :info_refs, params: params

            expect(log_data).to include('username' => user.username,
                                        'user_id' => user.id,
                                        'meta.user' => user.username)
          end
        end
      end

      context 'with exceptions' do
        before do
          allow(controller).to receive(:authenticate_user).and_return(true)
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

    describe 'POST #git_upload_pack' do
      before do
        allow(controller).to receive(:verify_workhorse_api!).and_return(true)
      end

      it 'returns 200' do
        post :git_upload_pack, params: params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  context 'when repository container is a project' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { project }
      let(:user) { project.owner }
      let(:access_checker_class) { Gitlab::GitAccess }

      describe 'POST #git_upload_pack' do
        before do
          allow(controller).to receive(:verify_workhorse_api!).and_return(true)
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

        context 'when project_statistics_sync feature flag is disabled' do
          before do
            stub_feature_flags(project_statistics_sync: false)
          end

          it 'updates project statistics async for projects' do
            expect(ProjectDailyStatisticsWorker).to receive(:perform_async)

            send_request
          end
        end

        it 'updates project statistics sync for projects' do
          expect { send_request }.to change {
            Projects::DailyStatisticsFinder.new(container).total_fetch_count
          }.from(0).to(1)
        end
      end
    end
  end

  context 'when repository container is a project wiki' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { create(:project_wiki, :empty_repo, project: project) }
      let(:user) { project.owner }
      let(:access_checker_class) { Gitlab::GitAccessWiki }
    end
  end

  context 'when repository container is a personal snippet' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { personal_snippet }
      let(:user) { personal_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }
    end
  end

  context 'when repository container is a project snippet' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { project_snippet }
      let(:user) { project_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }
    end
  end
end
