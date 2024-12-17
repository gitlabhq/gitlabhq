# frozen_string_literal: true

module QA
  RSpec.describe 'Create', product_group: :source_code do
    describe 'Protected branch support' do
      let(:branch_name) { 'protected-branch' }
      let(:commit_message) { 'Protected push commit message' }
      let(:project) { create(:project, :with_readme, name: 'protected-branch-project') }

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      context 'when developers and maintainers are allowed to push to a protected branch' do
        it 'user with push rights successfully pushes', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347756' do
          create_protected_branch(allowed_to_push: {
            roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
          })

          push = push_new_file(branch_name)

          expect(push.output).to match(/To create a merge request for protected-branch, visit/)
        end
      end

      context 'when developers and maintainers are not allowed to push to a protected branch' do
        it 'user without push rights fails to push', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347757',
          quarantine: {
            issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/426739',
            type: :flaky
          } do
          create_protected_branch(allowed_to_push: {
            roles: Resource::ProtectedBranch::Roles::NO_ONE
          })

          expect { push_new_file(branch_name) }.to raise_error(QA::Support::Run::CommandError, /You are not allowed to push code to protected branches on this project\.([\s\S]+)\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
        end
      end

      def create_protected_branch(allowed_to_push:)
        create(:protected_branch, branch_name: branch_name, project: project, allowed_to_push: allowed_to_push)
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
