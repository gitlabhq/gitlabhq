module Keys
  class BaseService
    attr_accessor :user, :params

    def initialize(user, params)
      @user, @params = user, params
    end

    def notification_service
      NotificationService.new
    end
  end
end
