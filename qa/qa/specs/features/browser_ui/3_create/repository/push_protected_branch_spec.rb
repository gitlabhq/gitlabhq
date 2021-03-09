# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Protected branch support' do
      let(:branch_name) { 'protected-branch' }
      let(:commit_message) { 'Protected push commit message' }
      let(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'protected-branch-project'
          resource.initialize_with_readme = true
        end
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      context 'when developers and maintainers are allowed to push to a protected branch' do
        it 'user with push rights successfully pushes to the protected branch', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/447' do
          create_protected_branch(allowed_to_push: {
            roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
          })

          push = push_new_file(branch_name)

          expect(push.output).to match(/remote: To create a merge request for protected-branch, visit/)
        end
      end

      context 'when developers and maintainers are not allowed to push to a protected branch' do
        it 'user without push rights fails to push to the protected branch', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/449' do
          create_protected_branch(allowed_to_push: {
            roles: Resource::ProtectedBranch::Roles::NO_ONE
          })

          expect { push_new_file(branch_name) }.to raise_error(QA::Support::Run::CommandError, /remote: GitLab: You are not allowed to push code to protected branches on this project\.([\s\S]+)\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
        end
      end

      def create_protected_branch(allowed_to_push:)
        Resource::ProtectedBranch.fabricate_via_api! do |resource|
          resource.branch_name = branch_name
          resource.project = project
          resource.allowed_to_push = allowed_to_push
        end
      end

      def push_new_file(branch)
        Resource::Repository::ProjectPush.fabricate! do |resource|
          resource.project = project
          resource.file_name = 'new_file.md'
          resource.file_content = '# This is a new file'
          resource.commit_message = 'Add new_file.md'
          resource.branch_name = branch_name
          resource.new_branch = false
          resource.wait_for_push = false
        end
      end
    end
  end
end
