module Mattermost
  ClientError = Class.new(Mattermost::Error)

  class Client
    attr_reader :user

    def initialize(user)
      @user = user
    end

    def with_session(&blk)
      Mattermost::Session.new(user).with_session(&blk)
    end

    private

    # Should be used in a session manually
    def get(session, path, options = {})
      json_response session.get(path, options)
    end

    # Should be used in a session manually
    def post(session, path, options = {})
      json_response session.post(path, options)
    end

    def delete(session, path, options)
      json_response session.delete(path, options)
    end

    def session_get(path, options = {})
      with_session do |session|
        get(session, path, options)
      end
    end

    def session_post(path, options = {})
      with_session do |session|
        post(session, path, options)
      end
    end

    def session_delete(path, options = {})
      with_session do |session|
        delete(session, path, options)
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
