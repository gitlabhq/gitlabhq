# frozen_string_literal: true

module ContainerRegistry
  class Registry
    include Gitlab::Utils::StrongMemoize

    attr_reader :uri, :client, :path

    def initialize(uri, options = {})
      @uri = uri
      @options = options
      @path = @options[:path] || default_path
      @client = ContainerRegistry::Client.new(@uri, @options)
    end

    def gitlab_api_client
      strong_memoize(:gitlab_api_client) do
        token = Auth::ContainerRegistryAuthenticationService.import_access_token

        url = Gitlab.config.registry.api_url
        host_port = Gitlab.config.registry.host_port

        ContainerRegistry::GitlabApiClient.new(url, token: token, path: host_port)
      end
    end

    private

    def default_path
      @uri.sub(%r{^https?://}, '')
    end
  end
end
