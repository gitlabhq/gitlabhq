# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::GitHttpController, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :public, :repository) }
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

  context 'when repository container is a project' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { project }
      let(:user) { project.first_owner }
      let(:access_checker_class) { Gitlab::GitAccess }

      it_behaves_like 'handles unavailable Gitaly'

      describe 'POST #git_upload_pack' do
        before do
          allow(controller).to receive(:verify_workhorse_api!).and_return(true)
        end

        def send_request
          post :git_upload_pack, params: params
        end

        it 'updates project statistics sync for projects' do
          stub_feature_flags(disable_git_http_fetch_writes: false)

          expect { send_request }.to change {
            Projects::DailyStatisticsFinder.new(container).total_fetch_count
          }.from(0).to(1)
        end

        describe 'recording the onboarding progress', :sidekiq_inline do
          let_it_be(:namespace) { project.namespace }

          before do
            Onboarding::Progress.onboard(namespace)
            send_request
          end

          subject { Onboarding::Progress.completed?(namespace, :git_pull) }

          it { is_expected.to be(true) }
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
      end
    end

    context 'when the user is a deploy token' do
      it_behaves_like Repositories::GitHttpController do
        let(:container) { project }
        let(:user) { create(:deploy_token, :project, projects: [project]) }
        let(:access_checker_class) { Gitlab::GitAccess }
      end
    end
  end

  context 'when repository container is a project wiki' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { create(:project_wiki, :empty_repo, project: project) }
      let(:user) { project.first_owner }
      let(:access_checker_class) { Gitlab::GitAccessWiki }
    end
  end

  context 'when repository container is a personal snippet' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { personal_snippet }
      let(:user) { personal_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }

      it_behaves_like 'handles unavailable Gitaly'
    end
  end

  context 'when repository container is a project snippet' do
    it_behaves_like Repositories::GitHttpController do
      let(:container) { project_snippet }
      let(:user) { project_snippet.author }
      let(:access_checker_class) { Gitlab::GitAccessSnippet }

      it_behaves_like 'handles unavailable Gitaly'
    end
  end
end
