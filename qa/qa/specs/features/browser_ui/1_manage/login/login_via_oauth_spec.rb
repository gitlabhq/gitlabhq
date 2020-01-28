# frozen_string_literal: true

module QA
  # This test is skipped instead of quarantine because continuously running
  # this test may cause the user to hit GitHub's rate limits thus blocking the user.
  # Related issue: https://gitlab.com/gitlab-org/gitlab/issues/196517
  context 'Manage', :orchestrated, :oauth, :skip do
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
