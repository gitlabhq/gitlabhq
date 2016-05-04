module ImageRegistry
  class Tag
    attr_reader :repository, :name

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

    def [](key)
      return unless manifest
      manifest[key]
    end

    def digest
      return @digest if defined?(@digest)
      @digest = client.repository_tag_digest(repository.name, name)
    end

    def config
      return @config if defined?(@config)
      return unless manifest && manifest['config']
      blob = ImageRegistry::Blob.new(repository, manifest['config'])
      @config = ImageRegistry::Config.new(self, blob)
    end

    def created_at
      return unless config
      @created_at ||= DateTime.rfc3339(config['created'])
    end

    def layers
      return @layers if defined?(@layers)
      return unless manifest
      @layers = manifest['layers'].map do |layer|
        ImageRegistry::Blob.new(repository, layer)
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

    def client
      @client ||= repository.client
    end
  end
end
