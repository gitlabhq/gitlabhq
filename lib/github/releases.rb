module Github
  class Releases
    attr_reader :owner, :repo

    def initialize(owner, repo)
      @owner = owner
      @repo  = repo
    end

    def fetch
      Collection.new(releases_url).fetch
    end

    private

    def releases_url
      "/repos/#{owner}/#{repo}/releases"
    end
  end
end
