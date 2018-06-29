module BitbucketServer
  class Client
    attr_reader :connection

    def initialize(options = {})
      @connection = Connection.new(options)
    end

    def pull_requests(project_key, repo)
      path = "/projects/#{project_key}/repos/#{repo}/pull-requests?state=ALL"
      get_collection(path, :pull_request)
    end

    def activities(project_key, repo, pull_request)
      path = "/projects/#{project_key}/repos/#{repo}/pull-requests/#{pull_request}/activities"
      get_collection(path, :activity)
    end

    def repo(project, repo_name)
      parsed_response = connection.get("/projects/#{project}/repos/#{repo_name}")
      # XXXX TODO Handle failure
      BitbucketServer::Representation::Repo.new(parsed_response)
    end

    def repos
      path = "/repos"
      get_collection(path, :repo)
    end

    private

    def get_collection(path, type)
      paginator = BitbucketServer::Paginator.new(connection, path, type)
      BitbucketServer::Collection.new(paginator)
    end
  end
end
