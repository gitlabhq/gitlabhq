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

    def https_only
      domain_https = domain ? domain.https? : true
      project.pages_https_only? && domain_https
    end

    def source
      zip_source || legacy_source
    end

    def prefix
      if project.pages_group_root?
        '/'
      else
        project.full_path.delete_prefix(trim_prefix) + '/'
      end
    end

    private

    attr_reader :project, :trim_prefix, :domain

    def deployment
      strong_memoize(:deployment) do
        project.pages_metadatum.pages_deployment
      end
    end

    def zip_source
      return unless deployment&.file

      global_id = ::Gitlab::GlobalId.build(deployment, id: deployment.id).to_s

      {
        type: 'zip',
        path: deployment.file.url_or_file_path(expire_at: 1.day.from_now),
        global_id: global_id,
        sha256: deployment.file_sha256,
        file_size: deployment.size,
        file_count: deployment.file_count
      }
    end

    # TODO: remove support for legacy storage in 14.3 https://gitlab.com/gitlab-org/gitlab/-/issues/328712
    # we support this till 14.3 to allow people to still use legacy storage if something goes very wrong
    # on self-hosted installations, and we'll need some time to fix it
    def legacy_source
      return unless ::Settings.pages.local_store.enabled

      {
        type: 'file',
        path: File.join(project.full_path, 'public/')
      }
    end
  end
end
