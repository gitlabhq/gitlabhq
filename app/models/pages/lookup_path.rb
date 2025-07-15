# frozen_string_literal: true

module Pages
  class LookupPath
    include Gitlab::Utils::StrongMemoize

    def initialize(deployment:, root_namespace_id:, domain: nil, trim_prefix: nil, access_control: false)
      @deployment = deployment
      @project = deployment.project
      @root_namespace_id = root_namespace_id
      @domain = domain
      @trim_prefix = trim_prefix || @project.full_path
      @access_control = access_control
    end

    attr_accessor :access_control

    def project_id
      project.id
    end
    strong_memoize_attr :project_id

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
          expire_at: ::Gitlab::Pages::DEPLOYMENT_EXPIRATION.from_now
        ),
        global_id: global_id,
        sha256: deployment.file_sha256,
        file_size: deployment.size,
        file_count: deployment.file_count
      }
    end
    strong_memoize_attr :source

    def prefix
      ensure_leading_and_trailing_slash(prefix_value)
    end
    strong_memoize_attr :prefix

    def unique_host
      # When serving custom domain we don't present the unique host to avoid
      # GitLab Pages auto-redirect to the unique domain instead of keeping serving
      # from the custom domain.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/426435
      return if domain.present?

      project.pages_url_builder.unique_host
    end
    strong_memoize_attr :unique_host

    def root_directory
      return unless deployment

      deployment.root_directory
    end
    strong_memoize_attr :root_directory

    def primary_domain
      project&.project_setting&.pages_primary_domain
    end
    strong_memoize_attr :primary_domain

    private

    attr_reader :project, :root_namespace_id, :deployment, :trim_prefix, :domain

    def prefix_value
      return deployment.path_prefix if project.pages_url_builder.is_namespace_homepage?

      [project.full_path.delete_prefix(trim_prefix), deployment.path_prefix].compact.join('/')
    end

    def ensure_leading_and_trailing_slash(value)
      value
        .to_s
        .then { |s| s.start_with?("/") ? s : "/#{s}" }
        .then { |s| s.end_with?("/") ? s : "#{s}/" }
    end
  end
end
