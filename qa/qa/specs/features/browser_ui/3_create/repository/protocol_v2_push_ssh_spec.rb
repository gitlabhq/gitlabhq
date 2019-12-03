# frozen_string_literal: true

module QA
  # Git protocol v2 is temporarily disabled
  # https://gitlab.com/gitlab-org/gitlab-foss/issues/55769 (confidential)
  context 'Create', :quarantine do
    describe 'Push over SSH using Git protocol version 2', :requires_git_protocol_v2 do
      # Note: If you run this test against GDK make sure you've enabled sshd and
      # enabled setting the Git protocol by adding `AcceptEnv GIT_PROTOCOL` to
      # `sshd_config`
      # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md

      let(:key_title) { "key for ssh tests #{Time.now.to_f}" }
      let(:ssh_key) do
        Resource::SSHKey.fabricate! do |resource|
          resource.title = key_title
        end
      end

      around do |example|
        # Create an SSH key to be used with Git
        Flow::Login.sign_in
        ssh_key

        example.run

        # Remove the SSH key
        Flow::Login.sign_in
        Page::Main::Menu.perform(&:click_settings_link)
        Page::Profile::Menu.perform(&:click_ssh_keys)
        Page::Profile::SSHKeys.perform do |ssh_keys|
          ssh_keys.remove_key(key_title)
        end
      end

      it 'user pushes to the repository' do
        # Create a project to push to
        project = Resource::Project.fabricate! do |project|
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

            git_protocol_reported = repository.push_with_git_protocol(
              git_protocol,
              file_name,
              file_content)
          ensure
            repository.delete_ssh_key
          end
        end

        project.visit!
        project.wait_for_push_new_branch

        # Check that the push worked
        expect(page).to have_content(file_name)
        expect(page).to have_content(file_content)

        # And check that the correct Git protocol was used
        expect(git_protocol_reported).to eq(git_protocol)
      end
    end
  end
end
