# frozen_string_literal: true

module QA
  RSpec.describe 'Systems', product_group: :gitaly do
    describe 'Changing Gitaly repository storage', :requires_admin, except: { job: 'review-qa-*' } do
      praefect_manager = Service::PraefectManager.new

      shared_examples 'repository storage move' do
        it 'confirms a `finished` status after moving project repository storage' do
          expect(project).to have_file('README.md')
          expect { project.change_repository_storage(destination_storage[:name]) }.not_to raise_error
          expect { praefect_manager.verify_storage_move(source_storage, destination_storage, repo_type: :project) }
            .not_to raise_error

          Support::Retrier.retry_on_exception(sleep_interval: 5) do
            # For a short period of time after migrating, the repository can be 'read only' which may lead to errors
            # 'The repository is temporarily read-only. Please try again later.'
            Resource::Repository::Commit.fabricate_via_api! do |commit|
              commit.project = project
              commit.commit_message = 'Add new file'
              commit.add_files([
                                 { file_path: 'new_file', content: '# This is a new file' }
                               ])
            end
          end

          expect(project).to have_file('README.md')
          expect(project).to have_file('new_file')
        end
      end

      context 'when moving from one Gitaly storage to another', :orchestrated, :repository_storage,
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347827' do
        let(:source_storage) { { type: :gitaly, name: 'default' } }
        let(:destination_storage) { { type: :gitaly, name: QA::Runtime::Env.additional_repository_storage } }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'repo-storage-move-status'
            project.initialize_with_readme = true
            project.api_client = Runtime::API::Client.as_admin
          end
        end

        before do
          praefect_manager.gitlab = 'gitlab'
        end

        it_behaves_like 'repository storage move'
      end

      # Note: This test doesn't have the :orchestrated tag because it runs in the Test::Integration::Praefect
      # scenario with other tests that aren't considered orchestrated.
      # It also runs on staging using nfs-file07 as non-cluster storage and nfs-file22 as cluster/praefect storage
      context 'when moving from Gitaly to Gitaly Cluster', :requires_praefect,
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347828' do
        let(:source_storage) { { type: :gitaly, name: QA::Runtime::Env.non_cluster_repository_storage } }
        let(:destination_storage) { { type: :praefect, name: QA::Runtime::Env.praefect_repository_storage } }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'repo-storage-move'
            project.initialize_with_readme = true
            project.repository_storage = source_storage[:name]
            project.api_client = Runtime::API::Client.as_admin
          end
        end

        before do
          praefect_manager.gitlab = 'gitlab-gitaly-cluster'
        end

        it_behaves_like 'repository storage move'
      end

      # Note: This test doesn't have the :orchestrated tag because it runs in the Test::Integration::Praefect
      # scenario with other tests that aren't considered orchestrated.
      # It also runs on staging using nfs-file07 as non-cluster storage and nfs-file22 as cluster/praefect storage
      context 'when moving from Gitaly Cluster to Gitaly', :requires_praefect,
              testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/369204' do
        let(:source_storage) { { type: :praefect, name: QA::Runtime::Env.praefect_repository_storage } }
        let(:destination_storage) { { type: :gitaly, name: QA::Runtime::Env.non_cluster_repository_storage } }
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'repo-storage-move'
            project.initialize_with_readme = true
            project.repository_storage = source_storage[:name]
            project.api_client = Runtime::API::Client.as_admin
          end
        end

        before do
          praefect_manager.gitlab = 'gitlab-gitaly-cluster'
        end

        it_behaves_like 'repository storage move'
      end
    end
  end
end
