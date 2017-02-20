module Mattermost
  class CreateTeamService < ::BaseService
    def initialize(group, current_user)
      @group, @current_user = group, current_user
    end

    def execute
      # The user that creates the team will be Team Admin
      response = Mattermost::Team.new(current_user).create(@group)
      @group.build_chat_team(name: response['name'], team_id: response['id'])
    rescue Mattermost::ClientError => e
      @group.errors.add(:chat_team, e.message)
    end
  end
end
