module Ci
  class ArtifactBlob
    include BlobLike

    EXTENSIONS_SERVED_BY_PAGES = %w[.html .htm .txt .json].freeze

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
      return unless external_link?(job)

      full_path_parts = project.full_path_components
      top_level_group = full_path_parts.shift

      artifact_path = [
        '-', *full_path_parts, '-',
        'jobs', job.id,
        'artifacts', path
      ].join('/')

      "#{pages_config.protocol}://#{top_level_group}.#{pages_config.host}/#{artifact_path}"
    end

    def external_link?(job)
      pages_config.enabled &&
        pages_config.artifacts_server &&
        EXTENSIONS_SERVED_BY_PAGES.include?(File.extname(name)) &&
        job.project.public?
    end

    private

    def pages_config
      Gitlab.config.pages
    end
  end
end
