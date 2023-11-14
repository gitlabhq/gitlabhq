# frozen_string_literal: true

module QA
  RSpec.describe 'Govern', :orchestrated, :oauth, product_group: :authentication do
    describe 'OAuth' do
      it 'connects and logs in with GitHub OAuth',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/402405' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)

        Page::Main::Login.perform(&:sign_in_with_github)

        Vendor::Github::Page::Login.perform(&:login)

        expect(page).to have_content('Welcome to GitLab')
      end
    end
  end
end
