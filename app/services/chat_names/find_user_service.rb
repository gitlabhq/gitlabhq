# frozen_string_literal: true

module ChatNames
  class FindUserService
    def initialize(team_id, user_id)
      @team_id = team_id
      @user_id = user_id
    end

    def execute
      chat_name = find_chat_name
      return unless chat_name

      chat_name.update_last_used_at
      chat_name
    end

    private

    attr_reader :team_id, :user_id

    # rubocop: disable CodeReuse/ActiveRecord
    def find_chat_name
      ChatName.find_by(
        team_id: team_id,
        chat_id: user_id
      )
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
