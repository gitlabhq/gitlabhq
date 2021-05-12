# frozen_string_literal: true

module ChatNames
  class FindUserService
    def initialize(integration, params)
      @integration = integration
      @params = params
    end

    def execute
      chat_name = find_chat_name
      return unless chat_name

      chat_name.update_last_used_at
      chat_name
    end

    private

    # rubocop: disable CodeReuse/ActiveRecord
    def find_chat_name
      ChatName.find_by(
        integration: @integration,
        team_id: @params[:team_id],
        chat_id: @params[:user_id]
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
