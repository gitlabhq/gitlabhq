module BitbucketServer
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

    def repo(project, repo_name)
      parsed_response = connection.get("/projects/#{project}/repos/#{repo_name}")
      # XXXX TODO Handle failure
      BitbucketServer::Representation::Repo.new(parsed_response)
    end

    def repos
      path = "/repos"
      get_collection(path, :repo)
    end

    def user
      @user ||= begin
        parsed_response = connection.get('/user')
        BitbucketServer::Representation::User.new(parsed_response)
      end
    end

    private

    def get_collection(path, type)
      paginator = BitbucketServer::Paginator.new(connection, path, type)
      BitbucketServer::Collection.new(paginator)
    end
  end
end
