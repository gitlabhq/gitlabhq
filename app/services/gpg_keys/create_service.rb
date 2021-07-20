# frozen_string_literal: true

module GpgKeys
  class CreateService < Keys::BaseService
    def execute
      key = create(params)
      notification_service.new_gpg_key(key) if key.persisted?
      key
    end

    private

    def create(params)
      user.gpg_keys.create(params)
    end
  end
end

GpgKeys::CreateService.prepend_mod
