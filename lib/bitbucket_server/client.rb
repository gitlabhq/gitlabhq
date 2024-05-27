# frozen_string_literal: true

module BitbucketServer
  class Client
    attr_reader :connection

    def initialize(options = {})
      @connection = Connection.new(options)
    end

    def pull_requests(project_key, repo, page_offset: 0, limit: nil)
      path = "/projects/#{project_key}/repos/#{repo}/pull-requests?state=ALL"
      get_collection(path, :pull_request, page_offset: page_offset, limit: limit)
    end

    def activities(project_key, repo, pull_request_id, page_offset: 0, limit: nil)
      path = "/projects/#{project_key}/repos/#{repo}/pull-requests/#{pull_request_id}/activities"
      get_collection(path, :activity, page_offset: page_offset, limit: limit)
    end

    def repo(project, repo_name)
      parsed_response = connection.get("/projects/#{project}/repos/#{repo_name}")
      BitbucketServer::Representation::Repo.new(parsed_response)
    end

    def repos(page_offset: 0, limit: nil, filter: nil)
      path = "/repos"
      path += "?name=#{filter}" if filter
      get_collection(path, :repo, page_offset: page_offset, limit: limit)
    end

    def users(project_key, page_offset: 0, limit: nil)
      path = "/projects/#{project_key}/permissions/users"
      get_collection(path, :user, page_offset: page_offset, limit: limit)
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

    def get_collection(path, type, page_offset: 0, limit: nil)
      paginator = BitbucketServer::Paginator.new(connection, Addressable::URI.escape(path), type, page_offset: page_offset, limit: limit)
      BitbucketServer::Collection.new(paginator)
    end
  end
end
