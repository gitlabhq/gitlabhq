module Mattermost
  class Command < Session
    def self.create(team_id, trigger: 'gitlab', url:, icon_url:)
      command = {
        auto_complete: true,
        auto_complete_desc: 'List all available commands',
        auto_complete_hint: '[help]',
        description: 'Perform common operations on GitLab',
        display_name: 'GitLab Slash Commands',
        method: 'P',
        user_name: 'GitLab',
        trigger: trigger,
        url: url,
        icon_url: icon_url
      }

      post_command(command)['token']
    end

    private

    def post_command(command)
      post( "/teams/#{team_id}/commands/create", body: command.to_json).parsed_response
    end
  end
end
