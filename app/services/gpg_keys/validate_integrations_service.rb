# frozen_string_literal: true

module GpgKeys
  class ValidateIntegrationsService < Keys::BaseService
    ValidationError = Class.new(StandardError)

    def initialize(key)
      @key = key
    end

    def execute
      return false unless key.valid?

      validate_beyond_identity!

      key.errors.empty?
    end

    private

    attr_reader :key

    def validate_beyond_identity!
      integration = Integrations::BeyondIdentity.for_instance.first

      return unless integration&.activated?

      integration.execute({ key_id: key.primary_keyid, committer_email: key.user.email })
      key.externally_verified = true
    rescue ::Gitlab::BeyondIdentity::Client::Error => e
      key.errors.add(:base, "BeyondIdentity: #{e.message}")
    end
  end
end
