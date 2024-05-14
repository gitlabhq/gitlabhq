# frozen_string_literal: true

module GpgKeys
  class CreateService < Keys::BaseService
    def execute
      key = user.gpg_keys.build(params)

      return key unless validate(key)

      create(key)

      notification_service.new_gpg_key(key) if key.persisted?
      key
    end

    private

    def validate(key)
      return false unless key.valid?

      GpgKeys::ValidateIntegrationsService.new(key).execute
    end

    def create(key)
      key.save
      key
    end
  end
end

GpgKeys::CreateService.prepend_mod
