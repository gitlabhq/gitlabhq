module Mattermost
  class Team < Client
    def all
      session_get('/api/v3/teams/all').values
    end
  end
end
