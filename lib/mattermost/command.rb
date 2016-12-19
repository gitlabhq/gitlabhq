module Mattermost
  class Command
    def self.create(session, team_id, command)
      session.post("/api/v3/teams/#{team_id}/commands/create", body: command.to_json)['token']
    end
  end
end
