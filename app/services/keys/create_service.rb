module Keys
  class CreateService < ::Keys::BaseService
    def execute
      key = user.keys.create(params)
      notification_service.new_key(key) if key.persisted?
      key
    end
  end
end
