# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', product_group: :gitaly do
    describe 'Changing Gitaly repository storage',
      :requires_admin, :orchestrated, :skip_live_env, :repository_storage do
      praefect_manager = Service::PraefectManager.new

      shared_examples 'repository storage move' do
        it 'confirms a `finished` status after moving project repository storage' do
          expect(project).to have_file('README.md')
          expect { project.change_repository_storage(destination_storage[:name]) }.not_to raise_error
          expect { praefect_manager.verify_storage_move(source_storage, destination_storage, repo_type: :project) }
            .not_to raise_error

          Support::Retrier.retry_on_exception(sleep_interval: 1, max_attempts: 120) do
            # For a short period of time after migrating, the repository can be 'read only' which may lead to errors
            # 'The repository is temporarily read-only. Please try again later.'
            create(:commit, project: project, commit_message: 'Add new file', actions: [
              { action: 'create', file_path: 'new_file', content: '# This is a new file' }
            ])
          end

          expect(project).to have_file('README.md')
          expect(project).to have_file('new_file')
        end
      end

      context 'when moving from one Gitaly storage to another',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347827' do
        let(:source_storage) { { type: :gitaly, name: QA::Runtime::Env.non_cluster_repository_storage } }
        let(:destination_storage) { { type: :gitaly, name: QA::Runtime::Env.additional_repository_storage } }
        let(:project) do
          create(:project, :with_readme, name: 'repo-storage-move-status', api_client: Runtime::API::Client.as_admin)
        end

        before do
          praefect_manager.gitlab = 'gitlab'
        end

        it_behaves_like 'repository storage move'
      end

      context 'when moving from Gitaly to Gitaly Cluster',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347828' do
        let(:source_storage) { { type: :gitaly, name: QA::Runtime::Env.non_cluster_repository_storage } }
        let(:destination_storage) { { type: :praefect, name: QA::Runtime::Env.praefect_repository_storage } }
        let(:project) do
          QA::Runtime::Logger.info("source_storage #{source_storage}")
          QA::Runtime::Logger.info("destination_storage #{destination_storage}")
          create(:project,
            :with_readme,
            name: 'repo-storage-move',
            repository_storage: source_storage[:name],
            api_client: Runtime::API::Client.as_admin)
        end

        before do
          praefect_manager.gitlab = 'gitlab'
        end

        it_behaves_like 'repository storage move'
      end

      context 'when moving from Gitaly Cluster to Gitaly',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/369204' do
        let(:source_storage) { { type: :praefect, name: QA::Runtime::Env.praefect_repository_storage } }
        let(:destination_storage) { { type: :gitaly, name: QA::Runtime::Env.non_cluster_repository_storage } }
        let(:project) do
          QA::Runtime::Logger.info("source_storage #{source_storage}")
          QA::Runtime::Logger.info("destination_storage #{destination_storage}")
          create(:project,
            :with_readme,
            name: 'repo-storage-move',
            repository_storage: source_storage[:name],
            api_client: Runtime::API::Client.as_admin)
        end

        before do
          praefect_manager.gitlab = 'gitlab'
        end

        it_behaves_like 'repository storage move'
      end
    end
  end
end
