# frozen_string_literal: true

module Gitlab
  module BitbucketImport
    module Importers
      class RepositoryImporter
        include Loggable

        LABELS = [{ title: 'bug', color: '#FF0000' },
          { title: 'enhancement', color: '#428BCA' },
          { title: 'proposal', color: '#69D100' },
          { title: 'task', color: '#7F8C8D' }].freeze

        def initialize(project)
          @project = project
        end

        def execute
          log_info(import_stage: 'import_repository', message: 'starting import')

          if project.empty_repo?
            project.repository.import_repository(project.import_url)
            project.repository.fetch_as_mirror(project.import_url, refmap: refmap)

            validate_repository_size!

            set_default_branch
            update_clone_time
          end

          import_wiki
          create_labels

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

        def import_wiki
          return if project.wiki.repository_exists?

          project.wiki.repository.import_repository(wiki.import_url)
        rescue StandardError => e
          Gitlab::ErrorTracking.log_exception(
            e, import_stage: 'import_repository', message: 'failed to import wiki', error: e.message
          )
        end

        def create_labels
          LABELS.each do |label_params|
            ::Labels::FindOrCreateService.new(nil, project, label_params).execute(skip_authorization: true)
          end
        end

        def wiki
          WikiFormatter.new(project)
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

        def client
          Bitbucket::Client.new(project.import_data.credentials)
        end
      end
    end
  end
end

Gitlab::BitbucketImport::Importers::RepositoryImporter.prepend_mod
