# frozen_string_literal: true

module Keys
  class BaseService
    attr_accessor :user, :params

    def initialize(user, params = {})
      @user = user
      @params = params
      @ip_address = @params.delete(:ip_address)
    end

    def notification_service
      NotificationService.new
    end

    def todo_service
      TodoService.new
    end
  end
end
