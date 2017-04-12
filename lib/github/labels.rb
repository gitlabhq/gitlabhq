module Github
  class Labels
    attr_reader :owner, :repo

    def initialize(owner, repo)
      @owner = owner
      @repo  = repo
    end

    def fetch
      Collection.new(labels_url).fetch
    end

    private

    def labels_url
      "/repos/#{owner}/#{repo}/labels"
    end
  end
end
