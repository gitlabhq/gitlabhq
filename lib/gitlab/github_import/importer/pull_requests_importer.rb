# frozen_string_literal: true

module Gitlab
  module GithubImport
    module Importer
      class PullRequestsImporter
        include ParallelScheduling

        def importer_class
          PullRequestImporter
        end

        def representation_class
          Gitlab::GithubImport::Representation::PullRequest
        end

        def sidekiq_worker_class
          ImportPullRequestWorker
        end

        def id_for_already_imported_cache(pr)
          pr[:number]
        end

        def object_type
          :pull_request
        end

        def each_object_to_import
          super do |pr|
            update_repository if update_repository?(pr)
            yield pr
          end
        end

        def update_repository
          # We set this column _before_ fetching the repository, and this is
          # deliberate. If we were to update this column after the fetch we may
          # miss out on changes pushed during the fetch or between the fetch and
          # updating the timestamp.
          project.touch(:last_repository_updated_at)

          project.repository.fetch_remote(project.import_url, refmap: Gitlab::GithubImport.refmap, forced: true)

          pname = project.path_with_namespace

          Logger.info(
            message: 'GitHub importer finished updating repository',
            project_name: pname
          )

          repository_updates_counter.increment
        end

        def update_repository?(pr)
          last_update = project.last_repository_updated_at || project.created_at

          return false if pr[:updated_at] < last_update

          # PRs may be updated without there actually being new commits, thus we
          # check to make sure we only re-fetch if truly necessary.
          !(commit_exists?(pr.dig(:head, :sha)) && commit_exists?(pr.dig(:base, :sha)))
        end

        def commit_exists?(sha)
          project.repository.commit(sha).present?
        end

        def collection_method
          :pull_requests
        end

        def collection_options
          { state: 'all', sort: 'created', direction: 'asc' }
        end

        # To avoid overloading Gitaly, we use a smaller limit for pull requests than the one defined in the
        # application settings.
        def parallel_import_batch
          { size: 200, delay: 1.minute }
        end

        def repository_updates_counter
          @repository_updates_counter ||= Gitlab::Metrics.counter(
            :github_importer_repository_updates,
            'The number of times repositories have to be updated again'
          )
        end
      end
    end
  end
end
