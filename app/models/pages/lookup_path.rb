# frozen_string_literal: true

module Pages
  class LookupPath
    include Gitlab::Utils::StrongMemoize

    LegacyStorageDisabledError = Class.new(::StandardError)

    def initialize(project, trim_prefix: nil, domain: nil)
      @project = project
      @domain = domain
      @trim_prefix = trim_prefix || project.full_path
    end

    def project_id
      project.id
    end

    def access_control
      project.private_pages?
    end
    strong_memoize_attr :access_control

    def https_only
      domain_https = domain ? domain.https? : true
      project.pages_https_only? && domain_https
    end
    strong_memoize_attr :https_only

    def source
      return unless deployment&.file

      global_id = ::Gitlab::GlobalId.build(deployment, id: deployment.id).to_s

      {
        type: 'zip',
        path: deployment.file.url_or_file_path(
          expire_at: ::Gitlab::Pages::CacheControl::DEPLOYMENT_EXPIRATION.from_now
        ),
        global_id: global_id,
        sha256: deployment.file_sha256,
        file_size: deployment.size,
        file_count: deployment.file_count
      }
    end
    strong_memoize_attr :source

    def prefix
      if project.pages_namespace_url == project.pages_url
        '/'
      else
        project.full_path.delete_prefix(trim_prefix) + '/'
      end
    end
    strong_memoize_attr :prefix

    private

    attr_reader :project, :trim_prefix, :domain

    def deployment
      strong_memoize(:deployment) do
        project.pages_metadatum.pages_deployment
      end
    end
  end
end
