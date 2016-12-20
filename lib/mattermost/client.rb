module Mattermost
  class ClientError < Mattermost::Error; end

  class Client
    attr_reader :user

    def initialize(user)
      @user = user
    end

    private

    def with_session(&blk)
      Mattermost::Session.new(user).with_session(&blk)
    end

    def json_get(path, options = {})
      with_session do |session|
        json_response session.get(path, options)
      end
    end

    def json_post(path, options = {})
      with_session do |session|
        json_response session.post(path, options)
      end
    end

    def json_response(response)
      json_response = JSON.parse(response.body)

      unless response.success?
        raise Mattermost::ClientError.new(json_response['message'] || 'Undefined error')
      end

      json_response
    rescue JSON::JSONError
      raise Mattermost::ClientError.new('Cannot parse response')
    end
  end
end
