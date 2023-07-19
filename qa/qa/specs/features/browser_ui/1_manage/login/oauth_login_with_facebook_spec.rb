# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :orchestrated, :oauth, product_group: :authentication_and_authorization do
    describe 'OAuth' do
      it 'logs in with Facebook credentials',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/417115' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform(&:sign_in_with_facebook)

        Vendor::Facebook::Page::Login.perform(&:login)

        expect(page).to have_content('Welcome to GitLab')
      end
    end
  end
end
