# frozen_string_literal: true

module Bitbucket
  class Client
    attr_reader :connection

    PULL_REQUEST_VALUES = %w[
      pagelen
      size
      page
      next
      previous
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
      next
    ].freeze

    def initialize(options = {})
      @connection = Connection.new(options)
    end

    # Fetches data from the Bitbucket API and yields a Page object for every page
    # of data, without loading all of them into memory.
    #
    # method - The method name used for getting the data.
    # representation_type - The representation type name used to wrap the result
    # args - Arguments to pass to the method.
    def each_page(method, representation_type, *args)
      options =
        if args.last.is_a?(Hash)
          args.last
        else
          {}
        end

      loop do
        parsed_response = fetch_data(method, *args)
        object = Page.new(parsed_response, representation_type)

        yield object

        break unless object.next?

        options[:next_url] = object.next

        if args.last.is_a?(Hash)
          args[-1] = options
        else
          args.push(options)
        end
      end
    end

    def last_issue(repo)
      parsed_response = connection.get("/repositories/#{repo}/issues?pagelen=1&sort=-created_on&state=ALL")
      Bitbucket::Representation::Issue.new(parsed_response['values'].first)
    end

    def issues(repo, options = {})
      path = "/repositories/#{repo}/issues?sort=created_on"

      if options[:raw]
        path = options[:next_url] if options[:next_url]
        connection.get(path)
      else
        get_collection(path, :issue)
      end
    end

    def issue_comments(repo, issue_id)
      path = "/repositories/#{repo}/issues/#{issue_id}/comments?sort=created_on"
      get_collection(path, :comment)
    end

    def pull_requests(repo, options = {})
      path = "/repositories/#{repo}/pullrequests?state=ALL&sort=created_on&fields=#{pull_request_values}"

      if options[:raw]
        path = options[:next_url] if options[:next_url]
        connection.get(path)
      else
        get_collection(path, :pull_request)
      end
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

    def fetch_data(method, *args)
      case method
      when :pull_requests then pull_requests(*args)
      when :issues then issues(*args)
      else
        raise ArgumentError, "Unknown data method #{method}"
      end
    end

    def get_collection(path, type, page_number: nil, limit: nil)
      paginator = Paginator.new(connection, path, type, page_number: page_number, limit: limit)
      Collection.new(paginator)
    end

    def pull_request_values
      PULL_REQUEST_VALUES.join(',')
    end
  end
end
