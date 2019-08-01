# frozen_string_literal: true

module QA
  # Failure issue: https://gitlab.com/gitlab-org/quality/nightly/issues/121
  context 'Manage', :orchestrated, :oauth, :quarantine do
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
