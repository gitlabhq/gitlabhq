class GithubService
  class RemoteProject
    def initialize(url)
      @uri = URI.parse(url)
    end

    def api_url
      if host == 'github.com'
        'https://api.github.com'
      else
        "#{protocol}://#{host}/api/v3"
      end
    end

    def owner
      uri_path.split('/')[1]
    end

    def repository_name
      uri_path.split('/')[2]
    end

    private

    def host
      @uri.host
    end

    def protocol
      @uri.scheme
    end

    def uri_path
      @uri.path.sub('.git', '')
    end
  end
end
