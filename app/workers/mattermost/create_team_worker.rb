module Mattermost
  class CreateTeamWorker
    include Sidekiq::Worker
    include DedicatedSidekiqQueue

    def perform(group_id, current_user_id, options = {})
      @group = Group.find(group_id)
      current_user = User.find(current_user_id)

      options = team_params.merge(options)

      # The user that creates the team will be Team Admin
      response = Mattermost::Team.new(current_user).create(options)

      ChatTeam.create!(namespace: @group, name: response['name'], team_id: response['id'])
    end

    private

    def team_params
      {
        name: @group.path[0..59],
        display_name: @group.name[0..59],
        type: @group.public? ? 'O' : 'I' # Open vs Invite-only
      }
    end
  end
end
