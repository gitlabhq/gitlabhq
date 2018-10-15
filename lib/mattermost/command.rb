# frozen_string_literal: true

module Mattermost
  class Command < Client
    def create(params)
      response = session_post('/api/v4/commands',
        body: params.to_json)

      response['token']
    end
  end
end
