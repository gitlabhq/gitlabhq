# frozen_string_literal: true

module QA
  RSpec.describe 'Data Stores', product_group: :tenant_scale do
    shared_examples 'loads all images' do |admin|
      let(:api_client) { Runtime::API::Client.as_admin }

      let(:user) do
        Resource::User.fabricate_via_api! do |resource|
          resource.admin = admin
          resource.api_client = api_client
        end
      end

      after do
        user.remove_via_api!
      end

      it 'loads all images' do
        Flow::Login.sign_in(as: user)

        Page::Dashboard::Welcome.perform do |welcome|
          Support::Waiter.wait_until(sleep_interval: 2, max_duration: 60, reload_page: page,
            retry_on_exception: true) do
            expect(welcome).to have_welcome_title("Welcome to GitLab")
          end
          # This would be better if it were a visual validation test
          expect(welcome).to have_loaded_all_images
        end
      end
    end

    describe 'Check for broken images', :requires_admin, :reliable do
      context(
        'when logged in as a new user',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347885'
      ) do
        it_behaves_like 'loads all images', false
      end

      context(
        'when logged in as a new admin',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347884'
      ) do
        it_behaves_like 'loads all images', true
      end
    end
  end
end
