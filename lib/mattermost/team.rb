module Mattermost
  class Team < Client
    def all
      json_get('/api/v3/teams/all')
    end
  end
end
