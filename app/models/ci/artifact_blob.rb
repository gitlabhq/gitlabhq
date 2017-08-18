module Ci
  class ArtifactBlob
    include BlobLike

    attr_reader :entry

    def initialize(entry)
      @entry = entry
    end

    delegate :name, :path, to: :entry

    def id
      Digest::SHA1.hexdigest(path)
    end

    def size
      entry.metadata[:size]
    end

    def data
      "Build artifact #{path}"
    end

    def mode
      entry.metadata[:mode]
    end

    def external_storage
      :build_artifact
    end

    alias_method :external_size, :size
  end
end
