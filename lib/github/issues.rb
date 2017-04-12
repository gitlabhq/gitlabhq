module Github
  class Issues
    attr_reader :owner, :repo

    def initialize(owner, repo)
      @owner = owner
      @repo  = repo
    end

    def fetch
      Collection.new(issues_url).fetch(state: :all, sort: :created, direction: :asc, per_page: 10)
    end

    private

    def issues_url
      "/repos/#{owner}/#{repo}/issues"
    end
  end
end
