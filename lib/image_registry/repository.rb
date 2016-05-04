module ImageRegistry
  class Repository
    attr_reader :registry, :name

    def initialize(registry, name)
      @registry, @name = registry, name
    end

    def client
      @client ||= registry.client
    end

    def [](tag)
      ImageRegistry::Tag.new(self, tag)
    end

    def manifest
      return @manifest if defined?(@manifest)
      @manifest = client.repository_tags(name)
    end

    def valid?
      manifest.present?
    end

    def tags
      return @tags if defined?(@tags)
      return unless manifest && manifest['tags']
      @tags = manifest['tags'].map do |tag|
        ImageRegistry::Tag.new(self, tag)
      end
    end

    def delete_tags
      return unless tags
      tags.each(:delete)
    end
  end
end
