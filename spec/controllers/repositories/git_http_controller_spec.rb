# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project_with_design, :public, :repository) }
  let_it_be(:personal_snippet) { create(:personal_snippet, :public, :repository) }
  let_it_be(:project_snippet) { create(:project_snippet, :public, :repository, project: project) }

  shared_examples 'handles unavailable Gitaly' do
    let(:params) { super().merge(service: 'git-upload-pack') }

    before do
      request.headers.merge! auth_env(user.username, user.password, nil)
    end

    context 'when Gitaly is unavailable', :use_clean_rails_redis_caching do
      it 'responds with a 503 message' do
        expect(Gitlab::GitalyClient).to receive(:call).and_raise(GRPC::Unavailable)

        get :info_refs, params: params

        expect(response).to have_gitlab_http_status(:service_unavailable)
        expect(response.body).to eq('The git server, Gitaly, is not available at this time. Please contact your administrator.')
      end
    end
  end

  shared_examples 'handles user activity' do
    it 'updates the user activity' do
      activity_project = container.is_a?(PersonalSnippet) ? nil : project

      activity_service = instance_double(Users::ActivityService)

      args = { author: user, project: activity_project, namespace: activity_project&.namespace }
      expect(Users::ActivityService).to receive(:new).with(args).and_return(activity_service)

      expect(activity_service).to receive(:execute)

      get :info_refs, params: params
    end

    it 'publishes activity events accordingly' do
      if container.is_a?(Project)
        expect { get :info_refs, params: params }
          .to publish_event(Users::ActivityEvent)
          .with({
            user_id: user.id,
            namespace_id: project.root_ancestor.id
          })
      else
        expect { get :info_refs, params: params }
          .not_to publish_event(Users::ActivityEvent)
      end
    end
  end

  shared_examples 'handles logging git upload pack operation' do
    before do
      password = user.try(:password) || user.try(:token)
      request.headers.merge! auth_env(user.username, password, nil)
    end

    context 'with git pull/fetch/clone action' do
      let(:params) { super().merge(service: 'git-upload-pack') }

      it_behaves_like 'handles user activity'
    end
  end

  context 'when repository container is a project' do
    it_behaves_like described_class do
      let(:container) { project }
      let(:user) { project.first_owner }
      let(:access_checker_class) { Gitlab::GitAccess }

      it_behaves_like 'handles unavailable Gitaly'
      it_behaves_like 'handles logging git upload pack operation'

      describe 'POST #ssh_upload_pack' do
        it 'returns not found error' do
          allow(controller).to receive(:verify_workhorse_api!).and_return(true)

          post :ssh_upload_pack, params: params

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to eq 'Not found'
        end
      end

      describe 'POST #ssh_receive_pack' do
        before do
          request.headers.merge! auth_env(user.username, user.password, nil)
        end

        it 'returns not found error' do
          allow(controller).to receive(:verify_workhorse_api!).and_return(true)

          post :ssh_receive_pack, params: params

          expect(response).to have_gitlab_http_status(:not_found)
          expect(response.body).to eq 'Not found'
        end
      end

      describe 'POST #git_upload_pack' do
        before do
          allow(controller).to receive(:verify_workhorse_api!).and_return(true)
        end

        def send_request
          post :git_upload_pack, params: params
        end

        it 'updates project statistics async for projects' do
          stub_feature_flags(disable_git_http_fetch_writes: false)
          daily_statistics = Projects::DailyStatisticsFinder.new(container)
          expect do
            send_request
          end.to change {
            daily_statistics.fetches.each do |date_stat|
              date_stat.counter(:fetch_count).commit_increment!
            end
            Projects::DailyStatisticsFinder.new(container).total_fetch_count
          }.from(0).to(1)
        end

        context 'when disable_git_http_fetch_writes is enabled' do
          before do
            stub_feature_flags(disable_git_http_fetch_writes: true)
          end

          it 'does not increment statistics' do
            expect(Projects::FetchStatisticsIncrementService).not_to receive(:new)

            send_request
          end
        end

        context 'when disable_git_http_fetch_writes is disabled' do
          before do
            stub_feature_flags(disable_git_http_fetch_writes: false)
          end

          it 'increments statistics' do
            expect(Projects::FetchStatisticsIncrementService).to receive(:new).with(project).and_call_original

            send_request
          end
        end
      end
    end

    context 'when the user is a deploy token' do
      it_behaves_like described_class do
        let(:container) { project }
        let(:user) { create(:deploy_token, :project, projects: [project]) }
        let(:access_checker_class) { Gitlab::GitAccess }

        it_behaves_like 'handles logging git upload pack operation'
      end
    end
  end

  context 'when repository container is a project wiki' do
    it_behaves_like described_class do
      let(:container) { create(:project_wiki, :empty_repo, project: project) }
      let(:user) { project.first_owner }
      let(:access_checker_class) { Gitlab::GitAccessWiki }

      it_behaves_like 'handles logging git upload pack operation'
    end
  end

  context 'when repository container is a personal snippet' do
    it_behaves_like described_class do
      let(:container) { personal_snippet }
      let(:user) { personal_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }

      it_behaves_like 'handles unavailable Gitaly'
      it_behaves_like 'handles logging git upload pack operation'
    end
  end

  context 'when repository container is a project snippet' do
    it_behaves_like described_class do
      let(:container) { project_snippet }
      let(:user) { project_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }

      it_behaves_like 'handles unavailable Gitaly'
      it_behaves_like 'handles logging git upload pack operation'
    end
  end

  context 'when repository container is a design_management_repository' do
    let(:container) { project.design_management_repository }
    let(:access_checker_class) { Gitlab::GitAccessDesign }
    let(:repository_path) { "#{container.full_path}.git" }
    let(:params) { { repository_path: repository_path, service: 'git-upload-pack' } }

    describe 'GET #info_refs' do
      it 'calls the right access checker class with the right object' do
        allow(controller).to receive(:verify_workhorse_api!).and_return(true)

        access_double = double

        expect(access_checker_class).to receive(:new)
          .with(nil, container, 'http', hash_including({ repository_path: repository_path }))
          .and_return(access_double)

        allow(access_double).to receive(:check).and_return(false)

        get :info_refs, params: params
      end
    end
  end

  describe '#append_info_to_payload' do
    let(:log_payload) { {} }
    let(:container) { project.design_management_repository }
    let(:repository_path) { "#{container.full_path}.git" }
    let(:params) { { repository_path: repository_path, service: 'git-upload-pack' } }
    let(:repository_storage) { "default" }

    before do
      allow(controller).to receive(:append_info_to_payload).and_wrap_original do |method, *|
        method.call(log_payload)
      end
    end

    it 'appends metadata for logging' do
      post :git_upload_pack, params: params
      expect(controller).to have_received(:append_info_to_payload)
      expect(log_payload.dig(:metadata, :repository_storage)).to eq(repository_storage)
    end
  end
end
