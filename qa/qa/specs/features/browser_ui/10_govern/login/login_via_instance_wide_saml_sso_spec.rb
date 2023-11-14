# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :orchestrated, :instance_saml, product_group: :authentication do
    describe 'Instance wide SAML SSO' do
      it(
        'user logs in to gitlab with SAML SSO',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347895'
      ) do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform(&:sign_in_with_saml)

        Vendor::SamlIdp::Page::Login.perform do |login_page|
          login_page.login('user1', 'user1pass')
        end

        Page::Dashboard::Welcome.perform do |welcome|
          expect(welcome).to have_content('Welcome to GitLab')
        end
      end
    end
  end
end
