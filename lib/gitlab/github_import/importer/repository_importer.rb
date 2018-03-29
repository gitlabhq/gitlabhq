# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class RepositoryImporter
        include Gitlab::ShellAdapter

        attr_reader :project, :client

        def initialize(project, client)
          @project = project
          @client = client
        end

        # Returns true if we should import the wiki for the project.
        def import_wiki?
          client.repository(project.import_source)&.has_wiki &&
            !project.wiki_repository_exists? &&
            Gitlab::GitalyClient::RemoteService.exists?(wiki_url)
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
          project.repository.fetch_as_mirror(project.import_url, refmap: refmap, forced: true, remote_name: 'github')

          true
        rescue Gitlab::Git::Repository::NoRepository, Gitlab::Shell::Error => e
          fail_import("Failed to import the repository: #{e.message}")
        end

        def import_wiki_repository
          wiki_path = "#{project.disk_path}.wiki"
          storage_path = project.repository_storage_path

          gitlab_shell.import_repository(storage_path, wiki_path, wiki_url)

          true
        rescue Gitlab::Shell::Error => e
          if e.message !~ /repository not exported/
            project.create_wiki
            fail_import("Failed to import the wiki: #{e.message}")
          else
            true
          end
        end

        def wiki_url
          project.import_url.sub(/\.git\z/, '.wiki.git')
        end

        def update_clone_time
          project.update_column(:last_repository_updated_at, Time.zone.now)
        end

        def fail_import(message)
          project.mark_import_as_failed(message)
          false
        end
      end
    end
  end
end
