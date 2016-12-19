module Mattermost
  class Team
    def self.all(session)
      session.get('/api/v3/teams/all').parsed_response
    end
  end
end
