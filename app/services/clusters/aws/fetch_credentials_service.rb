# frozen_string_literal: true

module Clusters
  module Aws
    class FetchCredentialsService
      attr_reader :provision_role

      MissingRoleError = Class.new(StandardError)

      def initialize(provision_role, provider: nil)
        @provision_role = provision_role
        @provider = provider
        @region = provider&.region || provision_role&.region || Clusters::Providers::Aws::DEFAULT_REGION
      end

      def execute
        raise MissingRoleError, 'AWS provisioning role not configured' unless provision_role.present?

        ::Aws::AssumeRoleCredentials.new(
          client: client,
          role_arn: provision_role.role_arn,
          role_session_name: session_name,
          external_id: provision_role.role_external_id,
          policy: session_policy
        ).credentials
      end

      private

      attr_reader :provider, :region

      def client
        ::Aws::STS::Client.new(**client_args)
      end

      def client_args
        { region: region, credentials: gitlab_credentials }.compact
      end

      def gitlab_credentials
        # These are not needed for IAM instance profiles
        return unless access_key_id.present? && secret_access_key.present?

        ::Aws::Credentials.new(access_key_id, secret_access_key)
      end

      def access_key_id
        Gitlab::CurrentSettings.eks_access_key_id
      end

      def secret_access_key
        Gitlab::CurrentSettings.eks_secret_access_key
      end

      ##
      # If we haven't created a provider record yet,
      # we restrict ourselves to read-only access so
      # that we can safely expose credentials to the
      # frontend (to be used when populating the
      # creation form).
      def session_policy
        if provider.nil?
          File.read(read_only_policy)
        end
      end

      def read_only_policy
        Rails.root.join('vendor', 'aws', 'iam', "eks_cluster_read_only_policy.json")
      end

      def session_name
        if provider.present?
          "gitlab-eks-cluster-#{provider.cluster_id}-user-#{provision_role.user_id}"
        else
          "gitlab-eks-autofill-user-#{provision_role.user_id}"
        end
      end
    end
  end
end
