module Mattermost
  class Command < Session
    def self.create(team_id, trigger: 'gitlab', url:, icon_url:)

      post_command(command)['token']
    end

    private

    def post_command(command)
      post( "/teams/#{team_id}/commands/create", body: command.to_json).parsed_response
    end
  end
end
