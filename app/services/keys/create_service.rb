# frozen_string_literal: true

module Keys
  class CreateService < ::Keys::BaseService
    prepend EE::Keys::CreateService

    def execute
      key = user.keys.create(params)
      notification_service.new_key(key) if key.persisted?
      key
    end
  end
end
