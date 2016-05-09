module ContainerRegistry
  class Repository
    attr_reader :registry, :name

    def initialize(registry, name)
      @registry, @name = registry, name
    end

    def client
      @client ||= registry.client
    end

    def path
      [registry.path, name].compact.join('/')
    end

    def [](tag)
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
      @tags ||= []
    end

    def delete_tags
      return unless tags
      tags.each(:delete)
    end

    def mount_blob(blob)
      return unless blob
      client.repository_mount_blob(name, blob.digest, blob.repository.name)
    end

    def mount_manifest(tag, manifest)
      client.put_repository_manifest(name, tag, manifest)
    end

    def copy_to(other_repository)
      tags.all? do |tag|
        tag.copy_to(other_repository)
      end
    end
  end
end
