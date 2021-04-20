# frozen_string_literal: true

module ContainerRegistry
  class Tag
    include Gitlab::Utils::StrongMemoize

    attr_reader :repository, :name

    delegate :registry, :client, to: :repository
    delegate :revision, :short_revision, to: :config_blob, allow_nil: true

    def initialize(repository, name)
      @repository = repository
      @name = name
    end

    def valid?
      manifest.present?
    end

    def latest?
      name == "latest"
    end

    def v1?
      manifest && manifest['schemaVersion'] == 1
    end

    def v2?
      manifest && manifest['schemaVersion'] == 2
    end

    def manifest
      strong_memoize(:manifest) do
        client.repository_manifest(repository.path, name)
      end
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
      strong_memoize(:digest) do
        client.repository_tag_digest(repository.path, name)
      end
    end

    def config_blob
      return unless manifest && manifest['config']

      strong_memoize(:config_blob) do
        repository.blob(manifest['config'])
      end
    end

    def config
      return unless config_blob&.data

      strong_memoize(:config) do
        ContainerRegistry::Config.new(self, config_blob)
      end
    end

    def created_at
      return unless config

      strong_memoize(:created_at) do
        DateTime.rfc3339(config['created'])
      rescue ArgumentError
        nil
      end
    end

    def layers
      return unless manifest

      strong_memoize(:layers) do
        layers = manifest['layers'] || manifest['fsLayers']

        layers.map do |layer|
          repository.blob(layer)
        end
      end
    end

    def put(digests)
      repository.client.put_tag(repository.path, name, digests)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def total_size
      return unless layers

      layers.map(&:size).sum if v2?
    end
    # rubocop: enable CodeReuse/ActiveRecord

    # Deletes the image associated with this tag
    # Note this will delete the image and all tags associated with it.
    # Consider using DeleteTagsService instead.
    def unsafe_delete
      return unless digest

      client.delete_repository_tag_by_digest(repository.path, digest)
    end
  end
end
