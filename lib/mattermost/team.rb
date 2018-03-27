module Mattermost
  class Team < Client
    # Returns **all** teams for an admin
    def all
      session_get('/api/v3/teams/all').values
    end

    # Creates a team on the linked Mattermost instance, the team admin will be the
    # `current_user` passed to the Mattermost::Client instance
    def create(name:, display_name:, type:)
      session_post('/api/v3/teams/create', body: {
        name: name,
        display_name: display_name,
        type: type
      }.to_json)
    end

    # The deletion is done async, so the response is fast.
    # On the mattermost side, this triggers an soft deletion
    def destroy(team_id:)
      session_delete("/api/v4/teams/#{team_id}")
    end
  end
end
