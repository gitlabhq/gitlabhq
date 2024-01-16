# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    ##
    # GCP keys used to store Google Cloud Service Accounts
    GCP_KEYS = %w[GCP_PROJECT_ID GCP_SERVICE_ACCOUNT GCP_SERVICE_ACCOUNT_KEY].freeze

    ##
    # This service deals with GCP Service Accounts in GitLab

    class ServiceAccountsService < ::CloudSeed::GoogleCloud::BaseService
      ##
      # Find GCP Service Accounts in a GitLab project
      #
      # This method looks up GitLab project's CI vars
      # and returns Google Cloud Service Accounts combinations
      # aligning GitLab project and ref to GCP projects

      def find_for_project
        group_vars_by_environment(GCP_KEYS).map do |environment_scope, value|
          {
            ref: environment_scope,
            gcp_project: value['GCP_PROJECT_ID'],
            service_account_exists: value['GCP_SERVICE_ACCOUNT'].present?,
            service_account_key_exists: value['GCP_SERVICE_ACCOUNT_KEY'].present?
          }
        end
      end

      def add_for_project(ref, gcp_project_id, service_account, service_account_key, is_protected)
        create_or_replace_project_vars(
          ref,
          'GCP_PROJECT_ID',
          gcp_project_id,
          is_protected
        )
        create_or_replace_project_vars(
          ref,
          'GCP_SERVICE_ACCOUNT',
          service_account,
          is_protected
        )
        create_or_replace_project_vars(
          ref,
          'GCP_SERVICE_ACCOUNT_KEY',
          service_account_key,
          is_protected
        )
      end
    end
  end
end
