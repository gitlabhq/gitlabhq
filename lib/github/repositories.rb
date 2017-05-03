module Github
  class Repositories
    attr_reader :options

    def initialize(options)
      @options = options
    end

    def fetch
      Collection.new(options).fetch(repos_url)
    end

    private

    def repos_url
      '/user/repos'
    end
  end
end
