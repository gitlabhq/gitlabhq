# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestsImporter
        include ParallelScheduling

        def execute
          page = 1

          loop do
            log_info(
              import_stage: 'import_pull_requests', message: "importing page #{page} using batch-size #{BATCH_SIZE}"
            )

            pull_requests = client.pull_requests(
              project_key, repository_slug, page_offset: page, limit: BATCH_SIZE
            ).to_a

            break if pull_requests.empty?

            commits_to_fetch = pull_requests.filter_map do |pull_request|
              next if already_processed?(pull_request)
              next unless pull_request.merged? || pull_request.closed?

              [pull_request.source_branch_sha, pull_request.target_branch_sha]
            end.flatten

            # Bitbucket Server keeps tracks of references for open pull requests in
            # refs/heads/pull-requests, but closed and merged requests get moved
            # into hidden internal refs under stash-refs/pull-requests. As a result,
            # they are not fetched by default.
            #
            # This method call explicitly fetches head and start commits for affected pull requests.
            # That allows us to correctly assign diffs and commits to merge requests.
            fetch_missing_commits(commits_to_fetch)

            pull_requests.each do |pull_request|
              # Needs to come before `already_processed?` as `jobs_remaining` resets to zero when the job restarts and
              # jobs_remaining needs to be the total amount of enqueued jobs
              job_waiter.jobs_remaining += 1

              next if already_processed?(pull_request)

              job_delay = calculate_job_delay(job_waiter.jobs_remaining)

              sidekiq_worker_class.perform_in(job_delay, project.id, pull_request.to_hash, job_waiter.key)

              mark_as_processed(pull_request)
            end

            page += 1
          end

          job_waiter
        end

        private

        def fetch_missing_commits(commits_to_fetch)
          return if commits_to_fetch.blank?
          return unless Feature.enabled?(:fetch_commits_for_bitbucket_server, project.group)

          project.repository.fetch_remote(project.import_url, refmap: commits_to_fetch, prune: false)
        rescue StandardError => e
          track_import_failure!(project, exception: e)
        end

        def sidekiq_worker_class
          ImportPullRequestWorker
        end

        def collection_method
          :pull_requests
        end

        def id_for_already_processed_cache(object)
          object.iid
        end
      end
    end
  end
end
