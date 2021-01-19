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
        # rubocop: disable CodeReuse/ActiveRecord
        def import_wiki?
          client_repository&.has_wiki &&
            !project.wiki_repository_exists? &&
            Gitlab::GitalyClient::RemoteService.exists?(wiki_url)
        end
        # rubocop: enable CodeReuse/ActiveRecord

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
          project.repository.fetch_as_mirror(project.import_url, refmap: refmap, forced: true, remote_name: 'github')

          project.change_head(default_branch) if default_branch

          # The initial fetch can bring in lots of loose refs and objects.
          # Running a `git gc` will make importing pull requests faster.
          Repositories::HousekeepingService.new(project, :gc).execute

          true
        rescue Gitlab::Git::Repository::NoRepository, Gitlab::Shell::Error => e
          fail_import("Failed to import the repository: #{e.message}")
        end

        def import_wiki_repository
          project.wiki.repository.import_repository(wiki_formatter.import_url)

          true
        rescue ::Gitlab::Git::CommandError => e
          if e.message !~ /repository not exported/
            project.create_wiki
            fail_import("Failed to import the wiki: #{e.message}")
          else
            true
          end
        end

        def wiki_url
          wiki_formatter.import_url
        end

        def update_clone_time
          project.update_column(:last_repository_updated_at, Time.zone.now)
        end

        def fail_import(message)
          project.import_state.mark_as_failed(message)
          false
        end

        private

        def default_branch
          client_repository&.default_branch
        end

        def client_repository
          strong_memoize(:client_repository) do
            client.repository(project.import_source)
          end
        end
      end
    end
  end
end
