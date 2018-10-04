# frozen_string_literal: true

module BitbucketServer
  class Client
    attr_reader :connection

    ServerError = Class.new(StandardError)

    SERVER_ERRORS = [SocketError,
                     OpenSSL::SSL::SSLError,
                     Errno::ECONNRESET,
                     Errno::ECONNREFUSED,
                     Errno::EHOSTUNREACH,
                     Net::OpenTimeout,
                     Net::ReadTimeout,
                     Gitlab::HTTP::BlockedUrlError,
                     BitbucketServer::Connection::ConnectionError].freeze

    def initialize(options = {})
      @connection = Connection.new(options)
    end

    def pull_requests(project_key, repo)
      path = "/projects/#{project_key}/repos/#{repo}/pull-requests?state=ALL"
      get_collection(path, :pull_request)
    end

    def activities(project_key, repo, pull_request_id)
      path = "/projects/#{project_key}/repos/#{repo}/pull-requests/#{pull_request_id}/activities"
      get_collection(path, :activity)
    end

    def repo(project, repo_name)
      parsed_response = connection.get("/projects/#{project}/repos/#{repo_name}")
      BitbucketServer::Representation::Repo.new(parsed_response)
    end

    def repos
      path = "/repos"
      get_collection(path, :repo)
    end

    def create_branch(project_key, repo, branch_name, sha)
      payload = {
        name: branch_name,
        startPoint: sha,
        message: 'GitLab temporary branch for import'
      }

      connection.post("/projects/#{project_key}/repos/#{repo}/branches", payload.to_json)
    end

    def delete_branch(project_key, repo, branch_name, sha)
      payload = {
        name: Gitlab::Git::BRANCH_REF_PREFIX + branch_name,
        dryRun: false
      }

      connection.delete(:branches, "/projects/#{project_key}/repos/#{repo}/branches", payload.to_json)
    end

    private

    def get_collection(path, type)
      paginator = BitbucketServer::Paginator.new(connection, Addressable::URI.escape(path), type)
      BitbucketServer::Collection.new(paginator)
    rescue *SERVER_ERRORS => e
      raise ServerError, e
    end
  end
end
