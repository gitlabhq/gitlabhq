# frozen_string_literal: true

module QA
  context 'Manage', :orchestrated, :oauth do
    describe 'OAuth login' do
      it 'User logs in to GitLab with GitHub OAuth' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform(&:sign_in_with_github)
        Vendor::Github::Page::Login.perform(&:login)

        expect(page).to have_content('Welcome to GitLab')
      end
    end
  end
end
