module ContainerRegistry
  class Registry
    attr_reader :uri, :client, :path

    def initialize(uri, options = {})
      @path = uri || options[:path]
      @uri = URI.parse(uri)
      @client = ContainerRegistry::Client.new(uri, options)
    end

    def [](name)
      ContainerRegistry::Repository.new(self, name)
    end
  end
end
