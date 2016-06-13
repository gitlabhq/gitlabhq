module ContainerRegistry
  class Repository
    attr_reader :registry, :name

    delegate :client, to: :registry

    def initialize(registry, name)
      @registry, @name = registry, name
    end

    def path
      [registry.path, name].compact.join('/')
    end

    def tag(tag)
      ContainerRegistry::Tag.new(self, tag)
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
      return [] unless manifest && manifest['tags']

      @tags = manifest['tags'].map do |tag|
        ContainerRegistry::Tag.new(self, tag)
      end
    end

    def blob(config)
      ContainerRegistry::Blob.new(self, config)
    end

    def delete_tags
      return unless tags

      tags.all?(&:delete)
    end
  end
end
