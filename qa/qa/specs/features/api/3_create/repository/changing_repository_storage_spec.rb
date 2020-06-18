# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Changing Gitaly repository storage', :orchestrated, :requires_admin do
      shared_examples 'repository storage move' do
        it 'confirms a `finished` status after moving project repository storage' do
          expect(project).to have_file('README.md')

          project.change_repository_storage(destination_storage)

          expect(Runtime::API::RepositoryStorageMoves).to have_status(project, 'finished', destination_storage)

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

      context 'when moving from one Gitaly storage to another', :repository_storage do
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'repo-storage-move-status'
            project.initialize_with_readme = true
          end
        end
        let(:destination_storage) { QA::Runtime::Env.additional_repository_storage }

        it_behaves_like 'repository storage move'
      end

      context 'when moving from Gitaly to Gitaly Cluster', :requires_praefect do
        let(:project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = 'repo-storage-move'
            project.initialize_with_readme = true
            project.repository_storage = 'gitaly'
          end
        end
        let(:destination_storage) { QA::Runtime::Env.praefect_repository_storage }

        it_behaves_like 'repository storage move'
      end
    end
  end
end
