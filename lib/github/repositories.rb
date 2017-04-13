module Github
  class Repositories
    def initialize(username)
      @username = username
    end

    def fetch
      Collection.new.fetch(repos_url)
    end

    private

    def repos_url
      '/user/repos'
    end
  end
end
