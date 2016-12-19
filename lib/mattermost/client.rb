module Mattermost
  class Client
    attr_reader :user

    def initialize(user)
      @user = user
    end

    private

    def with_session(&blk)
      Session.new(user).with_session(&blk)
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

      if response.success?
        json_response
      elsif json_response['message']
        raise json_response['message']
      else
        raise 'Undefined error'
      end
    end
  end
end
