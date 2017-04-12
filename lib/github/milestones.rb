module Github
  class Milestones
    attr_reader :owner, :repo

    def initialize(owner, repo)
      @owner = owner
      @repo  = repo
    end

    def fetch
      Collection.new(milestones_url).fetch
    end

    private

    def milestones_url
      "/repos/#{owner}/#{repo}/milestones"
    end
  end
end
