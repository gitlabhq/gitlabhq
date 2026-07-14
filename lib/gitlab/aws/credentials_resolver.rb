# frozen_string_literal: true

module Gitlab
  module Aws
    # Resolves AWS credentials for a service in the following order:
    #   1. assume role, if a role ARN is configured
    #   2. static access key + secret access key, if configured
    #   3. the AWS credential provider chain (environment variables, shared
    #      credentials profile, ECS credential service, EC2 instance profile)
    class CredentialsResolver
      extend Gitlab::Utils::StrongMemoize

      def self.resolve(region: nil, role_arn: nil, role_session_name: nil, access_key_id: nil, secret_access_key: nil)
        if role_arn.present?
          sts_client = ::Aws::STS::Client.new(region: region)

          return ::Aws::AssumeRoleCredentials.new(
            client: sts_client,
            role_arn: role_arn,
            role_session_name: role_session_name
          )
        end

        static_credentials = ::Aws::Credentials.new(access_key_id, secret_access_key)
        return static_credentials if static_credentials.set?

        credential_provider_chain
      end

      # Aws::CredentialProviderChain checks AWS access credential environment
      # variables, the AWS credential profile, the ECS credential service and
      # the EC2 credential service.
      #
      # See https://docs.aws.amazon.com/sdk-for-ruby/v3/developer-guide/credential-providers.html#credchain
      # for the full list and order of providers.
      def self.credential_provider_chain
        strong_memoize(:credential_provider_chain) do
          ::Aws::CredentialProviderChain.new.resolve
        end
      end
    end
  end
end
