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
        "#{project.full_path.delete_prefix(trim_prefix)}/"
      end
    end
    strong_memoize_attr :prefix

    def unique_host
      return unless project.project_setting.pages_unique_domain_enabled?

      project.pages_unique_host
    end
    strong_memoize_attr :unique_host

    def root_directory
      return unless deployment

      deployment.root_directory
    end
    strong_memoize_attr :root_directory

    private

    attr_reader :project, :trim_prefix, :domain

    def deployment
      project.pages_metadatum.pages_deployment
    end
    strong_memoize_attr :deployment
  end
end
