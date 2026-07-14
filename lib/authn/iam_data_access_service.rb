# frozen_string_literal: true

module Authn
  module IamDataAccessService
    # Must match the `serviceTokenHeader` constant in iam's dataaccess/server.go.
    SERVICE_TOKEN_HEADER = 'gitlab-iam-data-access-token'

    ConfigurationError = Class.new(StandardError)

    class << self
      include Gitlab::Utils::StrongMemoize

      def grpc_address
        grpc = iam_config.grpc
        if grpc.host.blank? || grpc.port.blank?
          raise ConfigurationError,
            'IAM data access gRPC service is not configured'
        end

        scheme = Rails.env.development? ? '' : 'tls://'
        "#{scheme}#{grpc.host}:#{grpc.port}"
      end

      def secret
        path = iam_config.secret_file
        raise ConfigurationError, 'IAM data access service secret_file is not configured' if path.blank?

        value = File.read(path).chomp
        raise ConfigurationError, 'IAM data access service secret_file is empty' if value.blank?

        value
      end
      strong_memoize_attr :secret

      private

      def iam_config
        Gitlab.config.iam_data_access_service
      end
    end
  end
end
