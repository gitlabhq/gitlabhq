module Keys
  class BaseService
    attr_accessor :user, :params

    def initialize(user, params)
      @user, @params = user, params
      @ip_address = @params.delete(:ip_address)
    end

    def notification_service
      NotificationService.new
    end
  end
end
