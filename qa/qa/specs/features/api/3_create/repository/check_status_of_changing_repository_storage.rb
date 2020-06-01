# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Gitaly repository storage', :orchestrated, :repository_storage, :requires_admin do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'repo-storage-status'
          project.initialize_with_readme = true
        end
      end

      it 'confirms a `finished` status after moving project repository storage' do
        expect(project).to have_file('README.md')

        project.change_repository_storage(QA::Runtime::Env.additional_repository_storage)

        expect(Runtime::API::RepositoryStorageMoves).to have_status(project, 'finished')

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
  end
end
