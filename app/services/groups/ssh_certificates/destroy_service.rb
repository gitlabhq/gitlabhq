# frozen_string_literal: true

module Groups
  module SshCertificates
    class DestroyService
      def initialize(group, params, current_user)
        @group = group
        @params = params
        @current_user = current_user
      end

      def execute
        ssh_certificate = group.ssh_certificates.find(params[:ssh_certificates_id])

        ssh_certificate.destroy!
        ServiceResponse.success(payload: { ssh_certificate: ssh_certificate })

      rescue ActiveRecord::RecordNotFound
        ServiceResponse.error(
          message: 'SSH Certificate not found',
          reason: :not_found
        )

      rescue ActiveRecord::RecordNotDestroyed
        ServiceResponse.error(
          message: 'SSH Certificate could not be deleted',
          reason: :method_not_allowed
        )
      end

      private

      attr_reader :group, :params, :current_user
    end
  end
end

Groups::SshCertificates::DestroyService.prepend_mod_with('Groups::SshCertificates::DestroyService')
