# frozen_string_literal: true

module QA
  # Git protocol v2 is temporarily disabled
  # https://gitlab.com/gitlab-org/gitlab-foss/issues/55769 (confidential)
  context 'Create', :quarantine do
    describe 'Push over HTTP using Git protocol version 2', :requires_git_protocol_v2 do
      it 'user pushes to the repository' do
        Flow::Login.sign_in

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

          repository.uri = project.repository_http_location.uri
          repository.use_default_credentials
          repository.clone
          repository.configure_identity(username, email)

          git_protocol_reported = repository.push_with_git_protocol(
            git_protocol,
            file_name,
            file_content)
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
