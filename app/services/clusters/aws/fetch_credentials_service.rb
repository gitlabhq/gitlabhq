# frozen_string_literal: true

module Clusters
  module Aws
    class FetchCredentialsService
      attr_reader :provision_role

      MissingRoleError = Class.new(StandardError)

      def initialize(provision_role, region:, provider: nil)
        @provision_role = provision_role
        @region = region
        @provider = provider
      end

      def execute
        raise MissingRoleError.new('AWS provisioning role not configured') unless provision_role.present?

        ::Aws::AssumeRoleCredentials.new(
          client: client,
          role_arn: provision_role.role_arn,
          role_session_name: session_name,
          external_id: provision_role.role_external_id
        ).credentials
      end

      private

      attr_reader :provider, :region

      def client
        ::Aws::STS::Client.new(credentials: gitlab_credentials, region: region)
      end

      def gitlab_credentials
        ::Aws::Credentials.new(access_key_id, secret_access_key)
      end

      def access_key_id
        Gitlab::CurrentSettings.eks_access_key_id
      end

      def secret_access_key
        Gitlab::CurrentSettings.eks_secret_access_key
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
