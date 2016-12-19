module Mattermost
  class Team
    def self.all(session)
      response_body = retreive_teams(session)

      response_body.has_key?('message') ? response_body : response_body.values
    end

    def self.retreive_teams(session)
      session.get('/api/v3/teams/all').parsed_response
    end
  end
end
