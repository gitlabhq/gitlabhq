module Ci
  class ArtifactBlob
    include BlobLike

    EXTENTIONS_SERVED_BY_PAGES = %w[.html .htm .txt].freeze

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

    def external_url(project, job)
      return unless external_link?

      components = project.full_path_components
      components << "-/jobs/#{job.id}/artifacts/file/#{path}"
      artifact_path = components[1..-1].join('/')

      "#{pages_config.protocol}://#{components[0]}.#{pages_config.host}/#{artifact_path}"
    end

    def external_link?
      pages_config.enabled &&
        pages_config.artifacts_server &&
        EXTENTIONS_SERVED_BY_PAGES.include?(File.extname(name))
    end

    private

    def pages_config
      Gitlab.config.pages
    end
  end
end
