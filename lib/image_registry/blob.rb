module ImageRegistry
  class Blob
    attr_reader :repository, :config

    def initialize(repository, config)
      @repository = repository
      @config = config || {}
    end

    def valid?
      digest.present?
    end

    def digest
      config['digest']
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

    def client
      @client ||= repository.client
    end

    def delete
      client.delete_blob(repository.name, digest)
    end

    def data
      return @data if defined?(@data)
      @data ||= client.blob(repository.name, digest, type)
    end
  end
end
