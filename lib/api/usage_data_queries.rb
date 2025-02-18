# frozen_string_literal: true

module API
  class UsageDataQueries < ::API::Base
    before { authenticated_as_admin! }

    feature_category :service_ping
    urgency :low

    namespace 'usage_data' do
      before do
        not_found! unless Feature.enabled?(:usage_data_queries_api, type: :ops)
      end

      desc 'Get raw SQL queries for usage data SQL metrics' do
        detail 'This feature was introduced in GitLab 13.11.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
      end

      get 'queries' do
        data = ::ServicePing::QueriesServicePing.for_current_reporting_cycle.pick(:payload) || {}

        present data
      end
    end
  end
end
