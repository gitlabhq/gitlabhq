module Mattermost
  class Command
    def self.create(session, team_id, command)
      response = session.post("/api/v3/teams/#{team_id}/commands/create", body: command.to_json).parsed_response

      if response.has_key?('message')
        response
      else
        response['token']
      end
    end
  end
end
