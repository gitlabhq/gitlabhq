module ContainerRegistry
  class Tag
    attr_reader :repository, :name

    delegate :registry, :client, to: :repository

    def initialize(repository, name)
      @repository, @name = repository, name
    end

    def valid?
      manifest.present?
    end

    def manifest
      return @manifest if defined?(@manifest)

      @manifest = client.repository_manifest(repository.name, name)
    end

    def path
      "#{repository.path}:#{name}"
    end

    def [](key)
      return unless manifest

      manifest[key]
    end

    def digest
      return @digest if defined?(@digest)

      @digest = client.repository_tag_digest(repository.name, name)
    end

    def config_blob
      return @config_blob if defined?(@config_blob)
      return unless manifest && manifest['config']

      @config_blob = repository.blob(manifest['config'])
    end

    def config
      return unless config_blob

      @config ||= ContainerRegistry::Config.new(self, config_blob)
    end

    def created_at
      return unless config

      @created_at ||= DateTime.rfc3339(config['created'])
    end

    def layers
      return @layers if defined?(@layers)
      return unless manifest

      @layers = manifest['layers'].map do |layer|
        repository.blob(layer)
      end
    end

    def total_size
      return unless layers

      layers.map(&:size).sum
    end

    def delete
      return unless digest

      client.delete_repository_tag(repository.name, digest)
    end
  end
end
