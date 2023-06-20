# frozen_string_literal: true

module Gitlab
  module APIAuthentication
    class TokenLocator
      UsernameAndPassword = Struct.new(:username, :password)

      include ActiveModel::Validations
      include ActionController::HttpAuthentication::Basic

      VALID_LOCATIONS = %i[
        http_basic_auth
        http_token
        http_bearer_token
        http_deploy_token_header
        http_job_token_header
        http_private_token_header
        http_header
        token_param
      ].freeze

      attr_reader :location

      validates :location, inclusion: { in: VALID_LOCATIONS }

      def initialize(location)
        @location = extract_location(location)
        validate!
      end

      def extract(request)
        case @location
        when :http_basic_auth
          extract_from_http_basic_auth request
        when :http_token
          extract_from_http_token request
        when :http_bearer_token
          extract_from_http_bearer_token request
        when :http_deploy_token_header
          extract_from_http_deploy_token_header request
        when :http_job_token_header
          extract_from_http_job_token_header request
        when :http_private_token_header
          extract_from_http_private_token_header request
        when :http_header
          extract_from_http_header request
        when :token_param
          extract_from_token_param request
        end
      end

      private

      def extract_location(location)
        case location
        when Symbol
          location
        when Hash
          result, @token_identifier = location.detect { |k, _v| VALID_LOCATIONS.include?(k) }
          result
        end
      end

      def extract_from_http_basic_auth(request)
        username, password = user_name_and_password(request)
        return unless username.present? && password.present?

        UsernameAndPassword.new(username, password)
      end

      def extract_from_http_token(request)
        password = request.headers['Authorization']
        return unless password.present?

        UsernameAndPassword.new(nil, password)
      end

      def extract_from_http_bearer_token(request)
        password = request.headers['Authorization']
        return unless password.present?

        UsernameAndPassword.new(nil, password.split(' ').last)
      end

      def extract_from_http_deploy_token_header(request)
        password = request.headers['Deploy-Token']
        return unless password.present?

        UsernameAndPassword.new(nil, password)
      end

      def extract_from_http_job_token_header(request)
        password = request.headers['Job-Token']
        return unless password.present?

        UsernameAndPassword.new(nil, password)
      end

      def extract_from_http_private_token_header(request)
        password = request.headers['Private-Token']
        return unless password.present?

        UsernameAndPassword.new(nil, password)
      end

      def extract_from_token_param(request)
        password = request.query_parameters['token']
        return unless password.present?

        UsernameAndPassword.new(nil, password)
      end

      def extract_from_http_header(request)
        password = request.headers[@token_identifier]
        return unless password.present?

        UsernameAndPassword.new(nil, password)
      end
    end
  end
end
