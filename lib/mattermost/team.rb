module Mattermost
  class Team < Session
    def self.team_admin
      body = get('/users/initial_load').parsed_response

      return [] unless body['team_members']

      team_ids = body['team_members'].map do |team|
        team['team_id'] if team['roles'].split.include?('team_admin')
      end.compact

      body['teams'].select do |team|
        team_ids.include?(team['id'])
      end
    end
  end
end
