module Mattermost
  class Team
    def self.team_admin(session)
      response_body = initial_load(session)
      return [] unless response_body['team_members']

      team_ids = response_body['team_members'].map do |team|
        team['team_id'] if team['roles'].split.include?('team_admin')
      end.compact

      response_body['teams'].select do |team|
        team_ids.include?(team['id'])
      end
    end

    def self.initial_load(session)
      session.get('/api/v3/users/initial_load').parsed_response
    end
  end
end
