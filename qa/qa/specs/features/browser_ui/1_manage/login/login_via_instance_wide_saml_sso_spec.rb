# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :orchestrated, :instance_saml do
    describe 'Instance wide SAML SSO' do
      it 'User logs in to gitlab with SAML SSO', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/671' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform(&:sign_in_with_saml)

        Vendor::SAMLIdp::Page::Login.perform do |login_page|
          login_page.login('user1', 'user1pass')
        end

        Page::Dashboard::Welcome.perform do |welcome|
          expect(welcome).to have_content('Welcome to GitLab')
        end
      end
    end
  end
end
