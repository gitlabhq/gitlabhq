module ContainerRegistry
  class Tag
    attr_reader :repository, :name

    delegate :registry, :client, to: :repository
    delegate :revision, :short_revision, to: :config_blob, allow_nil: true

    def initialize(repository, name)
      @repository, @name = repository, name
    end

    def valid?
      manifest.present?
    end

    def v1?
      manifest && manifest['schemaVersion'] == 1
    end

    def v2?
      manifest && manifest['schemaVersion'] == 2
    end

    def manifest
      @manifest ||= client.repository_manifest(repository.path, name)
    end

    def path
      "#{repository.path}:#{name}"
    end

    def location
      "#{repository.location}:#{name}"
    end

    def [](key)
      return unless manifest

      manifest[key]
    end

    def digest
      @digest ||= client.repository_tag_digest(repository.path, name)
    end

    def config_blob
      return @config_blob if defined?(@config_blob)
      return unless manifest && manifest['config']

      @config_blob = repository.blob(manifest['config'])
    end

    def config
      return unless config_blob

      @config ||= ContainerRegistry::Config.new(self, config_blob) if config_blob.data
    end

    def created_at
      return unless config

      @created_at ||= DateTime.rfc3339(config['created'])
    end

    def layers
      return @layers if defined?(@layers)
      return unless manifest

      layers = manifest['layers'] || manifest['fsLayers']

      @layers = layers.map do |layer|
        repository.blob(layer)
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def total_size
      return unless layers

      layers.map(&:size).sum if v2?
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def delete
      return unless digest

      client.delete_repository_tag(repository.path, digest)
    end
  end
end
