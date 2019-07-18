# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Protected branch support', :ldap_no_tls do
      let(:branch_name) { 'protected-branch' }
      let(:commit_message) { 'Protected push commit message' }
      let(:project) do
        Resource::Project.fabricate! do |resource|
          resource.name = 'protected-branch-project'
        end
      end

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)
      end

      after do
        # We need to clear localStorage because we're using it for the dropdown,
        # and capybara doesn't do this for us.
        # https://github.com/teamcapybara/capybara/issues/1702
        Capybara.execute_script 'localStorage.clear()'
      end

      context 'when developers and maintainers are allowed to push to a protected branch' do
        it 'user with push rights successfully pushes to the protected branch' do
          create_protected_branch(allow_to_push: true)

          push = push_new_file(branch_name)

          expect(push.output).to match(/remote: To create a merge request for protected-branch, visit/)
        end
      end

      context 'when developers and maintainers are not allowed to push to a protected branch' do
        it 'user without push rights fails to push to the protected branch' do
          create_protected_branch(allow_to_push: false)

          expect { push_new_file(branch_name) }.to raise_error(QA::Git::Repository::RepositoryCommandError, /remote: GitLab: You are not allowed to push code to protected branches on this project\.([\s\S]+)\[remote rejected\] #{branch_name} -> #{branch_name} \(pre-receive hook declined\)/)
        end
      end

      def create_protected_branch(allow_to_push:)
        Resource::Branch.fabricate! do |resource|
          resource.branch_name = branch_name
          resource.project = project
          resource.allow_to_push = allow_to_push
          resource.protected = true
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
