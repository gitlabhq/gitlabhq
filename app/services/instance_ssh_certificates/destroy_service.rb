# frozen_string_literal: true

module InstanceSshCertificates # rubocop:disable Gitlab/BoundedContexts -- Mirrors the existing InstanceSshCertificate model namespace
  class DestroyService
    def initialize(certificate_id, current_user:)
      @certificate_id = certificate_id
      @current_user = current_user
    end

    def execute
      unless current_user&.can_admin_all_resources?
        return ServiceResponse.error(message: 'Forbidden', reason: :forbidden)
      end

      return ServiceResponse.error(message: 'Not found', reason: :not_found) unless InstanceSshCertificate.available?

      certificate = InstanceSshCertificate.find(certificate_id)
      certificate.destroy!

      ServiceResponse.success(payload: { ssh_certificate: certificate })
    rescue ActiveRecord::RecordNotFound
      ServiceResponse.error(message: 'SSH Certificate not found', reason: :not_found)
    rescue ActiveRecord::RecordNotDestroyed
      ServiceResponse.error(message: 'SSH Certificate could not be deleted', reason: :unprocessable_entity)
    end

    private

    attr_reader :certificate_id, :current_user
  end
end
