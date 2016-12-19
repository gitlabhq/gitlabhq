module Mattermost
  class Team
    def self.all(session)
      retreive_teams(session)
    end

    def self.retreive_teams(session)
      session.get('/api/v3/teams/all').parsed_response
    end
  end
end
