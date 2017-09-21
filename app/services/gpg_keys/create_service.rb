module GpgKeys
  class CreateService < Keys::BaseService
    def execute
      key = user.gpg_keys.create(params)
      notification_service.new_gpg_key(key) if key.persisted?
      key
    end
  end
end
