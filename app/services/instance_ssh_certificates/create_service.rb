# frozen_string_literal: true

module InstanceSshCertificates # rubocop:disable Gitlab/BoundedContexts -- Mirrors the existing InstanceSshCertificate model namespace
  class CreateService
    def initialize(current_user:, params:)
      @current_user = current_user
      @params = params
    end

    def execute
      unless current_user&.can_admin_all_resources?
        return ServiceResponse.error(message: 'Forbidden', reason: :forbidden)
      end

      return ServiceResponse.error(message: 'Not found', reason: :not_found) unless InstanceSshCertificate.available?

      key = params[:key]
      fingerprint = Gitlab::SSHPublicKey.new(key).fingerprint_sha256&.delete_prefix('SHA256:')

      unless fingerprint
        return ServiceResponse.error(message: 'Validation failed: Invalid key', reason: :unprocessable_entity)
      end

      certificate = InstanceSshCertificate.create!(title: params[:title], key: key, fingerprint: fingerprint)

      ServiceResponse.success(payload: certificate)
    rescue ActiveRecord::RecordInvalid, ArgumentError => e
      ServiceResponse.error(message: e.message, reason: :unprocessable_entity)
    rescue ActiveRecord::RecordNotUnique
      ServiceResponse.error(
        message: 'Validation failed: Fingerprint must be unique. This CA has already been configured.',
        reason: :unprocessable_entity
      )
    end

    private

    attr_reader :current_user, :params
  end
end
