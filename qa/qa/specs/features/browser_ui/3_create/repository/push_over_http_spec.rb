# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Git push over HTTP', :ldap_no_tls do
      it 'user pushes code to the repository' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end
        project_push.project.visit!
        Page::Project::Show.act { wait_for_push }

        expect(page).to have_content('README.md')
        expect(page).to have_content('This is a test project')
      end
    end
  end
end
