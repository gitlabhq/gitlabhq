# frozen_string_literal: true

module ContainerRegistry
  class Blob
    attr_reader :repository, :config

    delegate :registry, :client, to: :repository

    def initialize(repository, config)
      @repository = repository
      @config = config || {}
    end

    def valid?
      digest.present?
    end

    def path
      "#{repository.path}@#{digest}"
    end

    def digest
      config['digest'] || config['blobSum']
    end

    def type
      config['mediaType']
    end

    def size
      config['size']
    end

    def revision
      digest.split(':')[1]
    end

    def short_revision
      revision[0..8]
    end

    def delete
      client.delete_blob(repository.path, digest)
    end

    def data
      @data ||= client.blob(repository.path, digest, type)
    end
  end
end
