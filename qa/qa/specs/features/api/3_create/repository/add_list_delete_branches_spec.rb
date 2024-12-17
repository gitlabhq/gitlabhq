# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    let(:project) { create(:project, name: 'project-qa-test', description: 'project for qa test') }

    describe 'Create, Retrieve and Delete branches via API', :requires_admin, product_group: :source_code do
      created_branch = 'create-branch'
      deleted_branch = 'delete-branch'
      filename = 'file.txt'
      default_branch_commit_message = "Add #{filename}"

      before do
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.try_add_credentials_to_netrc

          repository.act do
            init_repository
            use_default_identity

            commit_file(filename, 'Test file content', default_branch_commit_message)
            push_changes

            checkout(deleted_branch, new_branch: true)
            push_changes(deleted_branch)
          end
        end
        project.wait_for_push default_branch_commit_message
      end

      it(
        'creates, retrieves and deletes branches', :smoke,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347740'
      ) do
        # Create branch
        create(:branch, name: created_branch, project: project)

        # Retrieve branch
        delete_branch = build(:branch, name: deleted_branch, project: project).reload!

        # Delete branch
        delete_branch.remove_via_api!

        # Clone repository, verify branches and commits
        Git::Repository.perform do |repository|
          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.try_add_credentials_to_netrc

          repository.clone

          branches = repository.remote_branches
          expect(branches).to include(created_branch)
          expect(branches).not_to include(deleted_branch)

          expect(repository.commits.first).to include(default_branch_commit_message)

          repository.checkout(created_branch)
          expect(repository.commits.first).to include(default_branch_commit_message)
        end
      end
    end
  end
end
