# frozen_string_literal: true

module QA
  RSpec.describe 'SSH keys support', :smoke do
    key_title = "key for ssh tests #{Time.now.to_f}"
    key = nil

    before do
      Flow::Login.sign_in
    end

    it 'user can add an SSH key', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/929' do
      key = Resource::SSHKey.fabricate_via_browser_ui! do |resource|
        resource.title = key_title
      end

      expect(page).to have_content(key.title)
      expect(page).to have_content(key.md5_fingerprint)
    end

    # Note this context ensures that the example it contains is executed after the example above. Be aware of the order of execution if you add new examples in either context.
    context 'after adding an ssh key' do
      it 'can delete an ssh key', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/930' do
        Page::Main::Menu.perform(&:click_settings_link)
        Page::Profile::Menu.perform(&:click_ssh_keys)
        Page::Profile::SSHKeys.perform do |ssh_keys|
          ssh_keys.remove_key(key.title)
        end

        expect(page).not_to have_content("Title: #{key.title}")
        expect(page).not_to have_content(key.md5_fingerprint)
      end
    end
  end
end
