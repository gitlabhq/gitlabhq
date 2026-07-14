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

      desc 'List all Service Ping SQL queries' do
        detail 'Lists all raw SQL queries used to compute Service Ping. This action is behind the ' \
          '`usage_data_queries_api` feature flag. Administrators only.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags ['usage_data']
      end

      route_setting :authorization, permissions: :read_usage_data_query, boundary_type: :instance
      get 'queries' do
        data = ::ServicePing::QueriesServicePing.for_current_reporting_cycle.pick(:payload) || {}

        present data
      end
    end
  end
end
