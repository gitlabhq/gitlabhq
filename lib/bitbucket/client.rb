# frozen_string_literal: true

module Bitbucket
  class Client
    attr_reader :connection

    PULL_REQUEST_VALUES = %w[
      values.comment_count
      values.task_count
      values.type
      values.id
      values.title
      values.description
      values.state
      values.merge_commit
      values.close_source_branch
      values.closed_by
      values.author
      values.reason
      values.created_on
      values.updated_on
      values.destination
      values.source
      values.links
      values.summary
      values.reviewers
    ].freeze

    def initialize(options = {})
      @connection = Connection.new(options)
    end

    def last_issue(repo)
      parsed_response = connection.get("/repositories/#{repo}/issues?pagelen=1&sort=-created_on&state=ALL")
      Bitbucket::Representation::Issue.new(parsed_response['values'].first)
    end

    def issues(repo)
      path = "/repositories/#{repo}/issues?sort=created_on"
      get_collection(path, :issue)
    end

    def issue_comments(repo, issue_id)
      path = "/repositories/#{repo}/issues/#{issue_id}/comments?sort=created_on"
      get_collection(path, :comment)
    end

    def pull_requests(repo)
      path = "/repositories/#{repo}/pullrequests?state=ALL&sort=created_on&fields=#{pull_request_values}"
      get_collection(path, :pull_request)
    end

    def pull_request_comments(repo, pull_request)
      path = "/repositories/#{repo}/pullrequests/#{pull_request}/comments?sort=created_on"
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
      path = "/repositories?role=member&sort=created_on"
      path += "&q=name~\"#{filter}\"" if filter

      get_collection(path, :repo)
    end

    def user
      @user ||= begin
        parsed_response = connection.get('/user')
        Representation::User.new(parsed_response)
      end
    end

    def users(workspace_key, page_number: nil, limit: nil)
      path = "/workspaces/#{workspace_key}/members"
      get_collection(path, :user, page_number: page_number, limit: limit)
    end

    private

    def get_collection(path, type, page_number: nil, limit: nil)
      paginator = Paginator.new(connection, path, type, page_number: page_number, limit: limit)
      Collection.new(paginator)
    end

    def pull_request_values
      PULL_REQUEST_VALUES.join(',')
    end
  end
end
