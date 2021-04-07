# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Changing Gitaly repository storage', :requires_admin do
      praefect_manager = Service::PraefectManager.new

      shared_examples 'repository storage move' do
        it 'confirms a `finished` status after moving project repository storage' do
          expect(project).to have_file('README.md')
          expect { project.change_repository_storage(destination_storage[:name]) }.not_to raise_error
          expect { praefect_manager.verify_storage_move(source_storage, destination_storage, repo_type: :project) }.not_to raise_error

          Resource::Repository::ProjectPush.fabricate! do |push|
            push.project = project
            push.file_name = 'new_file'
            push.file_content = '# This is a new file'
            push.commit_message = 'Add new file'
            push.new_branch = false
          end

          expect(project).to have_file('README.md')
          expect(project).to have_file('new_file')
        end
      end

      context 'when moving from one Gitaly storage to another', :orchestrated, :repository_storage, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/973' do
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
      context 'when moving from Gitaly to Gitaly Cluster', :requires_praefect, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1755', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/284645', type: :investigating } do
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
    end
  end
end
