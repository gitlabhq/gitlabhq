module Bitbucket
  class Client
    def initialize(options = {})
      @connection = Connection.new(options)
    end

    def issues(repo)
      path = "/repositories/#{repo}/issues"
      paginator = Paginator.new(connection, path, :issue)

      Collection.new(paginator)
    end

    def issue_comments(repo, issue_id)
      path = "/repositories/#{repo}/issues/#{issue_id}/comments"
      paginator = Paginator.new(connection, path, :comment)

      Collection.new(paginator)
    end

    def pull_requests(repo)
      path = "/repositories/#{repo}/pullrequests?state=ALL"
      paginator = Paginator.new(connection, path, :pull_request)

      Collection.new(paginator)
    end

    def pull_request_comments(repo, pull_request)
      path = "/repositories/#{repo}/pullrequests/#{pull_request}/comments"
      paginator = Paginator.new(connection, path, :pull_request_comment)

      Collection.new(paginator)
    end

    def pull_request_diff(repo, pull_request)
      path = "/repositories/#{repo}/pullrequests/#{pull_request}/diff"

      connection.get(path)
    end

    def repo(name)
      parsed_response = connection.get("/repositories/#{name}")
      Representation::Repo.new(parsed_response)
    end

    def repos
      path = "/repositories/#{user.username}"
      paginator = Paginator.new(connection, path, :repo)

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
