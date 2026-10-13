# frozen_string_literal: true

module API
  class UsageDataNonSqlMetrics < ::API::Base
    before { authenticated_as_admin! }

    feature_category :service_ping
    urgency :low

    namespace 'usage_data' do
      desc 'List all non-SQL metrics' do
        detail 'Lists all non-SQL metrics data used in the Service ping. Administrators only.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
        tags ['usage_data']
      end

      route_setting :authorization, permissions: :read_usage_data_metric, boundary_type: :instance,
        assignable_when: [:admin]
      get 'non_sql_metrics' do
        data = ::ServicePing::NonSqlServicePing.for_current_reporting_cycle.pick(:payload) || {}

        present data
      end
    end
  end
end
