module Bitbucket
  class Client
    def initialize(options = {})
      @connection = options.fetch(:connection, Connection.new(options))
    end

    def user
      parsed_response = connection.get('/user')
      Representation::User.new(parsed_response)
    end

    private

    attr_reader :connection
  end
end
