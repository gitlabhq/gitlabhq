# frozen_string_literal: true

module Bitbucket
  class Client
    attr_reader :connection

    def initialize(options = {})
      @connection = Connection.new(options)
    end

    def issues(repo)
      path = "/repositories/#{repo}/issues"
      get_collection(path, :issue)
    end

    def issue_comments(repo, issue_id)
      path = "/repositories/#{repo}/issues/#{issue_id}/comments"
      get_collection(path, :comment)
    end

    def pull_requests(repo)
      path = "/repositories/#{repo}/pullrequests?state=ALL"
      get_collection(path, :pull_request)
    end

    def pull_request_comments(repo, pull_request)
      path = "/repositories/#{repo}/pullrequests/#{pull_request}/comments"
      get_collection(path, :pull_request_comment)
    end

    def pull_request_diff(repo, pull_request)
      path = "/repositories/#{repo}/pullrequests/#{pull_request}/diff"
      connection.get(path)
    end

    def repo(name)
      parsed_response = connection.get("/repositories/#{name}")
      Representation::Repo.new(parsed_response)
    end

    def repos(filter: nil)
      path = "/repositories?role=member"
      path += "&q=name~\"#{filter}\"" if filter

      get_collection(path, :repo)
    end

    def user
      @user ||= begin
        parsed_response = connection.get('/user')
        Representation::User.new(parsed_response)
      end
    end

    private

    def get_collection(path, type)
      paginator = Paginator.new(connection, path, type)
      Collection.new(paginator)
    end
  end
end
