# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'Git push over HTTP', :ldap_no_tls do
      it 'user pushes code to the repository' do
        Flow::Login.sign_in

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.file_name = 'README.md'
          push.file_content = '# This is a test project'
          push.commit_message = 'Add README.md'
        end.project.visit!

        expect(page).to have_content('README.md')
        expect(page).to have_content('This is a test project')
      end
    end
  end
end
