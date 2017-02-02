module Mattermost
  class Team < Client
    # Returns **all** teams for an admin
    def all
      session_get('/api/v3/teams/all')
    end

    def create(params)
      session_post('/api/v3/teams/create', body: params.to_json)
    end
  end
end
