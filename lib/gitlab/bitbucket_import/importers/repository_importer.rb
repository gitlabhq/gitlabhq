# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class RepositoryImporter
        include Loggable

        def initialize(project)
          @project = project
        end

        def execute
          log_info(import_stage: 'import_repository', message: 'starting import')

          if project.empty_repo?
            resolved_address = get_resolved_address(project.unsafe_import_url)

            project.repository.import_repository(project.unsafe_import_url, resolved_address: resolved_address)
            project.repository.fetch_as_mirror(project.unsafe_import_url, refmap: refmap,
              resolved_address: resolved_address)

            validate_repository_size!

            set_default_branch
            update_clone_time
          end

          log_info(import_stage: 'import_repository', message: 'finished import')

          true
        rescue ::Gitlab::Git::CommandError => e
          Gitlab::ErrorTracking.log_exception(
            e, import_stage: 'import_repository', message: 'failed import', error: e.message
          )

          # Expire cache to prevent scenarios such as:
          # 1. First import failed, but the repo was imported successfully, so +exists?+ returns true
          # 2. Retried import, repo is broken or not imported but +exists?+ still returns true
          project.repository.expire_content_cache if project.repository_exists?

          raise
        end

        private

        attr_reader :project

        def refmap
          # We omit :heads and :tags since these are fetched in the import_repository
          ['+refs/pull-requests/*/to:refs/merge-requests/*/head']
        end

        def update_clone_time
          project.touch(:last_repository_updated_at)
        end

        def validate_repository_size!
          # Defined in EE
        end

        def set_default_branch
          default_branch = client.repo(project.import_source).default_branch

          project.change_head(default_branch) if default_branch
        end

        def get_resolved_address(url)
          validated_url, resolved_host = Gitlab::HTTP_V2::UrlBlocker.validate!(
            url,
            schemes: Project::VALID_IMPORT_PROTOCOLS,
            ports: Project::VALID_IMPORT_PORTS,
            allow_localhost: allow_local_requests?,
            allow_local_network: allow_local_requests?,
            dns_rebind_protection: dns_rebind_protection?,
            deny_all_requests_except_allowed: Gitlab::CurrentSettings.deny_all_requests_except_allowed?,
            outbound_local_requests_allowlist: Gitlab::CurrentSettings.outbound_local_requests_whitelist # rubocop:disable Naming/InclusiveLanguage -- existing setting
          )

          return '' if resolved_host.blank? || !validated_url.scheme.in?(%w[http https])

          validated_url.hostname.to_s
        end

        def allow_local_requests?
          Gitlab::CurrentSettings.allow_local_requests_from_web_hooks_and_services?
        end

        def dns_rebind_protection?
          return false if Gitlab.http_proxy_env?

          Gitlab::CurrentSettings.dns_rebinding_protection_enabled?
        end

        def client
          ::Import::BitbucketImport::ClientFactory.for(project)
        end
      end
    end
  end
end

Gitlab::BitbucketImport::Importers::RepositoryImporter.prepend_mod
