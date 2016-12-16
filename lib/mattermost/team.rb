module Mattermost
  class Team < Session
    def self.team_admin
      return [] unless initial_load['team_members']

      team_ids = initial_load['team_members'].map do |team|
        team['team_id'] if team['roles'].split.include?('team_admin')
      end.compact

      initial_load['teams'].select do |team|
        team_ids.include?(team['id'])
      end
    end

    private

    def initial_load
      @initial_load ||= get('/users/initial_load').parsed_response
    end
  end
end
