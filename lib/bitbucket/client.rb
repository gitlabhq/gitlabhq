module Bitbucket
  class Client
    def initialize(options = {})
      @connection = options.fetch(:connection, Connection.new(options))
    end

    def issues(repo)
      relative_path = "/repositories/#{repo}/issues"
      paginator = Paginator.new(connection, relative_path, :issue)

      Collection.new(paginator)
    end


    def repo(name)
      parsed_response = connection.get("/repositories/#{name}")
      Representation::Repo.new(parsed_response)
    end

    def repos
      relative_path = "/repositories/#{user.username}"
      paginator = Paginator.new(connection, relative_path, :repo)

      Collection.new(paginator)
    end

    def user
      @user ||= begin
        parsed_response = connection.get('/user')
        Representation::User.new(parsed_response)
      end
    end

    private

    attr_reader :connection
  end
end
