module ChatNames
  class FindUserService
    def initialize(chat_names, params)
      @chat_names = chat_names
      @params = params
    end

    def execute
      @chat_names.find_by(
        team_id: @params[:team_id],
        chat_id: @params[:user_id]
      )
    end
  end
end
