module Mattermost
  class Command < Session
    def self.all(team_id)
      get("/teams/#{team_id}/commands/list_team_commands").parsed_response
    end

    # params should be a hash, which supplies _at least_:
    # - trigger => The slash command, no spaces, cannot start with a /
    # - url => What is the URL to trigger here?
    # - icon_url => Supply a link to the icon
    def self.create(team_id, params)
      command = {
        auto_complete: true,
        auto_complete_desc: 'List all available commands',
        auto_complete_hint: '[help]',
        description: 'Perform common operations on GitLab',
        display_name: 'GitLab',
        method: 'P',
        user_name: 'GitLab',
        trigger: 'gitlab',
      }.merge(params)

      response = post( "/teams/#{team_id}/commands/create", body: command.to_json)

      response.parsed_response['token']
    end
  end
end
