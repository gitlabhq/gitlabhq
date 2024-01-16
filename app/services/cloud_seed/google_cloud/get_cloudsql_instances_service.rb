# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class GetCloudsqlInstancesService < ::CloudSeed::GoogleCloud::BaseService
      CLOUDSQL_KEYS = %w[GCP_PROJECT_ID GCP_CLOUDSQL_INSTANCE_NAME GCP_CLOUDSQL_VERSION].freeze

      def execute
        group_vars_by_environment(CLOUDSQL_KEYS).map do |environment_scope, value|
          {
            ref: environment_scope,
            gcp_project: value['GCP_PROJECT_ID'],
            instance_name: value['GCP_CLOUDSQL_INSTANCE_NAME'],
            version: value['GCP_CLOUDSQL_VERSION']
          }
        end
      end
    end
  end
end
