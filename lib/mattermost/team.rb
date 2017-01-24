module Mattermost
  class Team < Client
    def all
      session_get('/api/v3/teams/all')
    end
  end
end
