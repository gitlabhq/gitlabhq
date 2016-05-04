module ImageRegistry
  class Registry
    attr_reader :uri, :client

    def initialize(uri, options = {})
      @uri = URI.parse(uri)
      @client = ImageRegistry::Client.new(uri, options)
    end

    def [](name)
      ImageRegistry::Repository.new(self, name)
    end
  end
end
