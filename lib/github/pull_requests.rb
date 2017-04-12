module Github
  class PullRequests
    attr_reader :owner, :repo

    def initialize(owner, repo)
      @owner = owner
      @repo  = repo
    end

    def fetch
      Collection.new(pull_requests_url).fetch(state: :all, sort: :created, direction: :asc)
    end

    private

    def pull_requests_url
      "/repos/#{owner}/#{repo}/pulls"
    end
  end
end
