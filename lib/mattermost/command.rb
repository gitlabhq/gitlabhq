module Mattermost
  class Command
    def self.create(session, params)
      response = session.post("/api/v3/teams/#{params[:team_id]}/commands/create",
        body: params.to_json)

      if response.success?
        response.parsed_response['token']
      elsif response.parsed_response.try(:has_key?, 'message')
        raise response.parsed_response['message']
      else
        raise 'Failed to create a new command'
      end
    end
  end
end
