# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Push over SSH using Git protocol version 2', :requires_git_protocol_v2 do
      # Note: If you run this test against GDK make sure you've enabled sshd and
      # enabled setting the Git protocol by adding `AcceptEnv GIT_PROTOCOL` to
      # `sshd_config`
      # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md

      let(:key_title) { "key for ssh tests #{Time.now.to_f}" }
      let(:ssh_key) do
        Resource::SSHKey.fabricate_via_api! do |resource|
          resource.title = key_title
        end
      end

      around do |example|
        # Create an SSH key to be used with Git, then remove it after the test
        Flow::Login.sign_in
        ssh_key

        example.run

        ssh_key.remove_via_api!

        Page::Main::Menu.perform(&:sign_out_if_signed_in)
      end

      it 'user pushes to the repository', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1763' do
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'git-protocol-project'
        end

        file_name = 'README.md'
        file_content = 'Test Git protocol v2'
        git_protocol = '2'
        git_protocol_reported = nil

        # Use Git to clone the project, push a file to it, and then check the
        # supported Git protocol
        Git::Repository.perform do |repository|
          username = 'GitLab QA'
          email = 'root@gitlab.com'

          repository.uri = project.repository_ssh_location.uri

          begin
            repository.use_ssh_key(ssh_key)
            repository.clone
            repository.configure_identity(username, email)
            repository.default_branch = project.default_branch
            repository.checkout(project.default_branch, new_branch: true)

            git_protocol_reported = repository.push_with_git_protocol(
              git_protocol,
              file_name,
              file_content)
          ensure
            repository.delete_ssh_key
          end
        end

        project.wait_for_push_new_branch
        project.visit!

        expect(git_protocol_reported).to eq(git_protocol)

        Page::Project::Show.perform do |show|
          expect(show).to have_file(file_name)
          expect(show).to have_readme_content(file_content)
        end
      end
    end
  end
end
