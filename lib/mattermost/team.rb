module Mattermost
  class Team
    def self.all(session)
      response = session.get('/api/v3/teams/all')

      if response.success?
        response.parsed_response
      elsif response.parsed_response.try(:has_key?, 'message')
        raise response.parsed_response['message']
      else
        raise 'Failed to list teams'
      end
    end
  end
end
