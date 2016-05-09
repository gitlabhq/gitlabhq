module ContainerRegistry
  class Registry
    attr_reader :uri, :client

    def initialize(uri, options = {})
      @uri = URI.parse(uri)
      @client = ContainerRegistry::Client.new(uri, options)
    end

    def [](name)
      ContainerRegistry::Repository.new(self, name)
    end
  end
end
