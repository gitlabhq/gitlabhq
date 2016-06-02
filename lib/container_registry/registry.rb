module ContainerRegistry
  class Registry
    attr_reader :uri, :client, :path

    def initialize(uri, options = {})
      @uri = uri
      @path = options[:path] || default_path
      @client = ContainerRegistry::Client.new(uri, options)
    end

    def repository(name)
      ContainerRegistry::Repository.new(self, name)
    end

    private

    def default_path
      @uri.sub(/^https?:\/\//, '')
    end
  end
end
