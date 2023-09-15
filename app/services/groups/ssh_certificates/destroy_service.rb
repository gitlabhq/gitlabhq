# frozen_string_literal: true

module Groups
  module SshCertificates
    class DestroyService
      def initialize(group, params)
        @group = group
        @params = params
      end

      def execute
        ssh_certificate = group.ssh_certificates.find(params[:ssh_certificates_id])

        ssh_certificate.destroy!
        ServiceResponse.success

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

      attr_reader :group, :params
    end
  end
end
