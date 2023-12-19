# frozen_string_literal: true

module Integrations
  module GoogleCloudPlatform
    class Jwt < ::JSONWebToken::RSAToken
      extend ::Gitlab::Utils::Override

      JWT_OPTIONS_ERROR = 'This jwt needs jwt claims audience and wlif to be set.'

      NoSigningKeyError = Class.new(StandardError)

      def initialize(project:, user:, claims:)
        super

        raise ArgumentError, JWT_OPTIONS_ERROR if claims[:audience].blank? || claims[:wlif].blank?

        @claims = claims
        @project = project
        @user = user
      end

      def encoded
        @custom_payload.merge!(custom_claims)

        super
      end

      private

      override :subject
      def subject
        "project_#{@project.id}_user_#{@user.id}"
      end

      override :key_data
      def key_data
        @key_data ||= begin
          # TODO Feels strange to use the CI signing key but do
          # we have a different signing key?
          key_data = Gitlab::CurrentSettings.ci_jwt_signing_key

          raise NoSigningKeyError unless key_data

          key_data
        end
      end

      def custom_claims
        {
          namespace_id: namespace.id.to_s,
          namespace_path: namespace.full_path,
          root_namespace_path: root_namespace.full_path,
          root_namespace_id: root_namespace.id.to_s,
          project_id: @project.id.to_s,
          project_path: @project.full_path,
          user_id: @user&.id.to_s,
          user_login: @user&.username,
          user_email: @user&.email,
          wlif: @claims[:wlif]
        }
      end

      def namespace
        @project.namespace
      end

      def root_namespace
        @project.root_namespace
      end

      override :issuer
      def issuer
        Feature.enabled?(:oidc_issuer_url) ? Gitlab.config.gitlab.url : Settings.gitlab.base_url
      end

      override :audience
      def audience
        @claims[:audience]
      end

      override :kid
      def kid
        rsa_key = OpenSSL::PKey::RSA.new(key_data)
        rsa_key.public_key.to_jwk[:kid]
      end
    end
  end
end
