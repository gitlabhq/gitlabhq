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

      url_project_path = project.full_path.partition('/').last

      artifact_path = [
        '-', url_project_path, '-',
        'jobs', job.id,
        'artifacts', path
      ].join('/')

      "#{project.pages_group_url}/#{artifact_path}"
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
