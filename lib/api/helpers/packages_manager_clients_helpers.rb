# frozen_string_literal: true

module API
  module Helpers
    module PackagesManagerClientsHelpers
      extend Grape::API::Helpers
      include ::API::Helpers::PackagesHelpers

      def find_job_from_http_basic_auth
        return unless request.headers

        token = decode_token

        return unless token

        ::Ci::AuthJobFinder.new(token: token).execute
      end

      def find_deploy_token_from_http_basic_auth
        return unless request.headers

        token = decode_token

        return unless token

        DeployToken.active.find_by_token(token)
      end

      private

      def decode_token
        encoded_credentials = request.headers['Authorization'].to_s.split('Basic ', 2).second
        Base64.decode64(encoded_credentials || '').split(':', 2).second
      end
    end
  end
end
