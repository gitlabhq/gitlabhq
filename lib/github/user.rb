module Github
  class User
    attr_reader :username

    def initialize(username)
      @username = username
    end

    def get
      client.get(user_url).body
    end

    private

    def client
      @client ||= Github::Client.new
    end

    def user_url
      "/users/#{username}"
    end
  end
end
