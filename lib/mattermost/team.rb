module Mattermost
  class Team < Client
    # Returns **all** teams for an admin
    def all
      session_get('/api/v3/teams/all')
    end

    # Creates a team on the linked Mattermost instance, the team admin will be the
    # `current_user` passed to the Mattermost::Client instance
    def create(group, params)
      session_post('/api/v3/teams/create', body: new_team_params(group, params).to_json)
    end

    private

    MATTERMOST_TEAM_LENGTH_MAX = 59

    def new_team_params(group, options)
      {
        name: group.path[0..MATTERMOST_TEAM_LENGTH_MAX],
        display_name: group.name[0..MATTERMOST_TEAM_LENGTH_MAX],
        type: group.public? ? 'O' : 'I' # Open vs Invite-only
      }.merge(options)
    end
  end
end
