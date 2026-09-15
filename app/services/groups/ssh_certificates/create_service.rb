# frozen_string_literal: true

module Groups
  module SshCertificates
    class CreateService
      def initialize(group, params, current_user)
        @group = group
        @params = params
        @current_user = current_user
      end

      def execute
        key = params[:key]
        fingerprint = generate_fingerprint(key)

        return ServiceResponse.error(message: 'Group', reason: :forbidden) if group.has_parent?

        # return a key error instead of fingerprint error, as the user has no knowledge of fingerprint.
        unless fingerprint
          return ServiceResponse.error(message: 'Validation failed: Invalid key',
            reason: :unprocessable_entity)
        end

        result = group.ssh_certificates.create!(
          key: key,
          title: params[:title],
          fingerprint: fingerprint
        )
        ServiceResponse.success(payload: result)

      rescue ActiveRecord::RecordInvalid, ArgumentError => e
        ServiceResponse.error(
          message: e.message,
          reason: :unprocessable_entity
        )
      end

      private

      attr_reader :group, :params, :current_user

      def generate_fingerprint(key)
        Gitlab::SSHPublicKey.new(key).fingerprint_sha256&.delete_prefix('SHA256:')
      end
    end
  end
end

Groups::SshCertificates::CreateService.prepend_mod_with('Groups::SshCertificates::CreateService')
