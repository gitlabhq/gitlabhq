module Github
  class User
    attr_reader :username, :options

    def initialize(username, options)
      @username = username
      @options  = options
    end

    def get
      client.get(user_url).body
    end

    private

    def client
      @client ||= Github::Client.new(options)
    end

    def user_url
      "/users/#{username}"
    end
  end
end
