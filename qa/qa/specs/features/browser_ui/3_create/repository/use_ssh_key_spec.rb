# frozen_string_literal: true

module QA
  context 'Create' do
    describe 'SSH key support' do
      # Note: If you run this test against GDK make sure you've enabled sshd
      # See: https://gitlab.com/gitlab-org/gitlab-qa/blob/master/docs/run_qa_against_gdk.md

      let(:key_title) { "key for ssh tests #{Time.now.to_f}" }

      it 'user adds an ssh key and pushes code to the repository' do
        Flow::Login.sign_in

        key = Resource::SSHKey.fabricate! do |resource|
          resource.title = key_title
        end

        project_push = Resource::Repository::ProjectPush.fabricate! do |push|
          push.ssh_key = key
          push.file_name = 'README.md'
          push.file_content = '# Test Use SSH Key'
          push.commit_message = 'Add README.md'
        end

        project_push.project.visit!

        expect(page).to have_content('README.md')
        expect(page).to have_content('Test Use SSH Key')

        Page::Main::Menu.perform(&:click_settings_link)
        Page::Profile::Menu.perform(&:click_ssh_keys)

        Page::Profile::SSHKeys.perform do |ssh_keys|
          ssh_keys.remove_key(key_title)
        end
      end
    end
  end
end
