# frozen_string_literal: true

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
      # Old versions of Workhorse omit the size if the file is 0 bytes
      entry.metadata.fetch(:size, 0)
    end
    alias_method :external_size, :size

    def data
      "Build artifact #{path}"
    end

    def mode
      entry.metadata[:mode]
    end

    def external_storage
      :build_artifact
    end

    def external_url(job)
      job.project.pages_url_builder.artifact_url(entry, job)
    end

    def external_link?(job)
      job.project.pages_url_builder.artifact_url_available?(entry, job)
    end
  end
end
