# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class RepositoryImporter
        include Gitlab::Utils::StrongMemoize

        attr_reader :project, :client, :wiki_formatter

        def initialize(project, client)
          @project = project
          @client = client
          @wiki_formatter = ::Gitlab::LegacyGithubImport::WikiFormatter.new(project)
        end

        # Returns true if we should import the wiki for the project.
        def import_wiki?
          client_repository[:has_wiki] &&
            !project.wiki_repository_exists?
        end

        # Imports the repository data.
        #
        # This method will return true if the data was imported successfully or
        # the repository had already been imported before.
        def execute
          imported =
            # It's possible a repository has already been imported when running
            # this code, e.g. because we had to retry this job after
            # `import_wiki?` raised a rate limit error. In this case we'll skip
            # re-importing the main repository.
            if project.empty_repo?
              import_repository
            else
              true
            end

          update_clone_time if imported

          imported = import_wiki_repository if import_wiki? && imported

          imported
        end

        def import_repository
          project.ensure_repository

          refmap = Gitlab::GithubImport.refmap
          resolved_address = get_resolved_address(project.unsafe_import_url)
          project.repository.fetch_as_mirror(project.unsafe_import_url, refmap: refmap, forced: true,
            resolved_address: resolved_address)

          project.change_head(default_branch) if default_branch

          validate_repository_size!

          # The initial fetch can bring in lots of loose refs and objects.
          # Running a `git gc` will make importing pull requests faster.
          ::Repositories::HousekeepingService.new(project, :gc).execute

          true
        end

        def import_wiki_repository
          resolved_address = get_resolved_address(wiki_formatter.import_url)
          project.wiki.repository.import_repository(wiki_formatter.import_url, resolved_address: resolved_address)

          true
        rescue ::Gitlab::Git::CommandError, ::Gitlab::Git::Repository::NoRepository => e
          return true if e.message.include?('repository not exported') ||
            e.message.include?('repository at given URL not found')

          project.create_wiki
          raise e
        end

        def wiki_url
          wiki_formatter.import_url
        end

        def update_clone_time
          project.touch(:last_repository_updated_at)
        end

        private

        def default_branch
          client_repository[:default_branch]
        end

        strong_memoize_attr def client_repository
          client.repository(project.import_source)
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

        def validate_repository_size!
          # Defined in EE
        end
      end
    end
  end
end

Gitlab::GithubImport::Importer::RepositoryImporter.prepend_mod
