module Mattermost
  class CreateTeamWorker
    include Sidekiq::Worker
    include DedicatedSidekiqQueue

    sidekiq_options retry: 5

    # Add 5 seconds so the first retry isn't 1 second later
    sidekiq_retry_in do |count|
      5 + 5**n
    end

    def perform(group_id, current_user_id, options = {})
      group = Group.find_by(id: group_id)
      current_user = User.find_by(id: current_user_id)
      return unless group && current_user

      # The user that creates the team will be Team Admin
      response = Mattermost::Team.new(current_user).create(group, options)

      group.create_chat_team(name: response['name'], team_id: response['id'])
    end
  end
end
