module Mattermost
  class Command < Client
    def create(params)
      response = json_post("/api/v3/teams/#{params[:team_id]}/commands/create",
        body: params.to_json)

      response['token']
    end
  end
end
