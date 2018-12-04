# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'SSH key support' do
      # Note: If you run this test against GDK make sure you've enabled sshd
      # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md

      let(:key_title) { "key for ssh tests #{Time.now.to_f}" }

      it 'user adds an ssh key and pushes code to the repository' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        key = Resource::SSHKey.fabricate! do |resource|
          resource.title = key_title
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.ssh_key = key
          push.file_name = 'README.md'
          push.file_content = '# Test Use SSH Key'
          push.commit_message = 'Add README.md'
        end

        Page::Project::Show.act { wait_for_push }

        expect(page).to have_content('README.md')
        expect(page).to have_content('Test Use SSH Key')

        Page::Main::Menu.act { go_to_profile_settings }
        Page::Profile::Menu.act { click_ssh_keys }

        Page::Profile::SSHKeys.perform do |ssh_keys|
          ssh_keys.remove_key(key_title)
        end
      end
    end
  end
end
