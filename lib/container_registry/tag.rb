# frozen_string_literal: true

module ContainerRegistry
  class Tag
    include Gitlab::Utils::StrongMemoize

    attr_reader :repository, :name, :updated_at, :referrers, :published_at
    attr_writer :created_at, :manifest_digest, :revision, :total_size
    attr_accessor :media_type

    delegate :registry, :client, to: :repository

    def initialize(repository, name, from_api: false)
      @repository = repository
      @name = name
      @from_api = from_api
    end

    def referrers=(refs)
      @referrers = Array.wrap(refs).map { |ref| Referrer.new(ref['artifactType'], ref['digest'], self) }
    end

    def revision
      @revision || config_blob&.revision
    end

    def short_revision
      return unless revision

      revision[0..8]
    end

    def valid?
      from_api? || manifest.present?
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
        @manifest_digest || client.repository_tag_digest(repository.path, name)
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
      return @created_at if @created_at

      strong_memoize(:memoized_created_at) do
        next unless config

        DateTime.rfc3339(config['created'])
      rescue ArgumentError
        nil
      end
    end

    # this function will set and memoize a created_at
    # to avoid a #config_blob call.
    def force_created_at_from_iso8601(string_value)
      date = parse_iso8601_string(string_value)
      instance_variable_set(ivar(:memoized_created_at), date)
    end

    def updated_at=(string_value)
      return unless string_value

      @updated_at = parse_iso8601_string(string_value)
    end

    def published_at=(string_value)
      return unless string_value

      @published_at = parse_iso8601_string(string_value)
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

    def total_size
      return @total_size if @total_size

      return unless layers

      layers.sum(&:size) if v2?
    end

    # Deletes the image associated with this tag
    # Note this will delete the image and all tags associated with it.
    # Consider using DeleteTagsService instead.
    def unsafe_delete
      return unless digest

      client.delete_repository_tag_by_digest(repository.path, digest)
    end

    private

    def from_api?
      @from_api
    end

    def parse_iso8601_string(string_value)
      DateTime.iso8601(string_value)
    rescue ArgumentError
      nil
    end
  end
end
