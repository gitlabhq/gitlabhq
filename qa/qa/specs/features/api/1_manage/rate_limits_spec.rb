# frozen_string_literal: true

require 'airborne'

module QA
  RSpec.describe 'Manage with IP rate limits', :requires_admin, quarantine: { only: { subdomain: :staging }, issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/240936', type: :investigating } do
    describe 'Users API' do
      let(:api_client) { Runtime::API::Client.new(:gitlab, ip_limits: true) }
      let(:request) { Runtime::API::Request.new(api_client, '/users') }

      it 'GET /users', status_issue: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/441' do
        5.times do
          get request.url
          expect_status(200)
        end
      end
    end
  end
end
