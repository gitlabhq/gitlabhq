# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'SSH keys support', :smoke, product_group: :source_code do
      let(:key_title) { "key for ssh tests delete #{Time.now.to_f}" }

      before do
        Flow::Login.sign_in
      end

      it 'can delete an ssh key', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347820' do
        key = create(:ssh_key, title: key_title)

        Page::Main::Menu.perform(&:click_edit_profile_link)
        Page::Profile::Menu.perform(&:click_ssh_keys)
        Page::Profile::SSHKeys.perform do |ssh_keys|
          ssh_keys.remove_key(key.title)
        end

        expect(page).not_to have_content(key.title)
        expect(page).not_to have_content(key.sha256_fingerprint)
      end
    end
  end
end
