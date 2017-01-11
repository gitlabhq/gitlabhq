module Mattermost
  class Command < Client
    def create(params)
<<<<<<< HEAD
      response = session_post("/api/v3/teams/#{params[:team_id]}/commands/create",
=======
      response = json_post("/api/v3/teams/#{params[:team_id]}/commands/create",
>>>>>>> Revert removing of some files
        body: params.to_json)

      response['token']
    end
  end
end
