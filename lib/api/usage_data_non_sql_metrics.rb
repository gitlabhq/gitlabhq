# frozen_string_literal: true

module API
  class UsageDataNonSqlMetrics < ::API::Base
    before { authenticated_as_admin! }

    feature_category :service_ping
    urgency :low

    namespace 'usage_data' do
      before do
        not_found! unless Feature.enabled?(:usage_data_non_sql_metrics, type: :ops)
      end

      desc 'Get Non SQL usage ping metrics' do
        detail 'This feature was introduced in GitLab 13.11.'
        success code: 200
        failure [
          { code: 401, message: 'Unauthorized' },
          { code: 403, message: 'Forbidden' },
          { code: 404, message: 'Not Found' }
        ]
      end

      get 'non_sql_metrics' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/325534')

        data = Gitlab::Usage::ServicePingReport.for(output: :non_sql_metrics_values)

        present data
      end
    end
  end
end
