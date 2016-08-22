module Bitbucket
  class Client
    def initialize(options = {})
      @connection = options.fetch(:connection, Connection.new(options))
    end

    private

    attr_reader :connection
  end
end
