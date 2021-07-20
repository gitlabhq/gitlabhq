# frozen_string_literal: true

module API
  class UsageDataNonSqlMetrics < ::API::Base
    before { authenticated_as_admin! }

    feature_category :service_ping

    namespace 'usage_data' do
      before do
        not_found! unless Feature.enabled?(:usage_data_non_sql_metrics, default_enabled: :yaml, type: :ops)
      end

      desc 'Get Non SQL usage ping metrics' do
        detail 'This feature was introduced in GitLab 13.11.'
      end

      get 'non_sql_metrics' do
        Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/325534')

        data = Gitlab::UsageDataNonSqlMetrics.uncached_data

        present data
      end
    end
  end
end
