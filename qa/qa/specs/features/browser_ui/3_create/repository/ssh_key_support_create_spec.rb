# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_category: :source_code_management do
    describe 'SSH keys support', :smoke do
      let(:key_title) { "key for ssh tests create #{Time.now.to_f}" }

      key = nil

      before do
        Flow::Login.sign_in
      end

      after do
        Page::Profile::SSHKeys.perform { |ssh_keys| ssh_keys.remove_key(key.title) } if key
      end

      it 'user can add an SSH key', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347819' do
        key = Resource::SSHKey.fabricate_via_browser_ui! do |resource|
          resource.title = key_title
        end

        expect(page).to have_content(key.title)
        expect(page).to have_content(key.sha256_fingerprint)
      end
    end
  end
end
