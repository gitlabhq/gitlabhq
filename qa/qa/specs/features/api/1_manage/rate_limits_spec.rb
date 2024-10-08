# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin, :skip_live_env, only: {
    condition: -> { ENV['QA_RUN_TYPE']&.match?("e2e-test-on-omnibus") }
  } do
    describe 'rate limits', :blocking, product_group: :import_and_integrate do
      let(:rate_limited_user) { create(:user) }
      let(:api_client) { Runtime::API::Client.new(:gitlab, user: rate_limited_user) }
      let!(:request) { Runtime::API::Request.new(api_client, '/users') }

      before do
        Flow::Login.sign_in_as_admin
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_network_settings)

        Page::Admin::Settings::Network.perform do |setting|
          setting.expand_user_ip_limits do |page|
            page.enable_authenticated_api_request_limit
            page.set_authenticated_api_request_limit_per_user(5)
            page.set_authenticated_api_request_limit_seconds(60)
            page.save_settings
          end
        end
      end

      after do
        rate_limited_user.remove_via_api!
      end

      it 'throttles authenticated api requests by user',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347881' do
          5.times do
            res = RestClient.get request.url
            expect(res.code).to be(200)
          end

          expect { RestClient.get request.url }.to raise_error do |e|
            expect(e.class).to be(RestClient::TooManyRequests)
          end
        end
    end
  end
end
