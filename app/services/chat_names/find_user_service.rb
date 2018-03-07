module ChatNames
  class FindUserService
    def initialize(service, params)
      @service = service
      @params = params
    end

    def execute
      chat_name = find_chat_name
      return unless chat_name

      chat_name.update_last_used_at
      chat_name
    end

    private

    def find_chat_name
      ChatName.find_by(
        service: @service,
        team_id: @params[:team_id],
        chat_id: @params[:user_id]
      )
    end
  end
end
