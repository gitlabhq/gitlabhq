# frozen_string_literal: true

module QA
  RSpec.describe 'Manage', :requires_admin, :skip_live_env, only: {
    condition: -> { ENV['QA_RUN_TYPE']&.match?("e2e-test-on-omnibus") }
  } do
    describe 'rate limits', product_group: :import_and_integrate do
      let(:rate_limited_user) { create(:user, :with_personal_access_token) }
      let(:api_client) { rate_limited_user.api_client }
      let!(:request) { Runtime::API::Request.new(api_client, '/users') }

      it 'throttles authenticated api requests by user',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347881' do
        with_application_settings(
          throttle_authenticated_api_requests_per_period: 100,
          throttle_authenticated_api_period_in_seconds: 7200,
          throttle_authenticated_api_enabled: true
        ) do
          100.times do
            res = RestClient.get request.url
            expect(res.code).to be(200)
          end

          expect { RestClient.get request.url }.to raise_error do |e|
            expect(e.class).to be(RestClient::TooManyRequests)
          end
        end
      end

      private

      def with_application_settings(**hargs)
        QA::Runtime::ApplicationSettings.set_application_settings(**hargs)
        yield
      ensure
        QA::Runtime::ApplicationSettings.restore_application_settings(*hargs.keys)
      end
    end
  end
end
