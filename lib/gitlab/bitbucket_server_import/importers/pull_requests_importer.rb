# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestsImporter
        include ParallelScheduling

        def execute
          page = page_counter.current

          loop do
            log_info(
              import_stage: 'import_pull_requests',
              message: "importing page #{page} using batch-size #{concurrent_import_jobs_limit}"
            )

            pull_requests = client.pull_requests(
              project_key, repository_slug, page_offset: page, limit: concurrent_import_jobs_limit
            ).to_a

            break if pull_requests.empty?

            # Bitbucket Server keeps tracks of references for open pull requests in
            # refs/heads/pull-requests, but closed and merged requests get moved
            # into hidden internal refs under stash-refs/pull-requests. As a result,
            # they are not fetched by default.
            #
            # This method call explicitly fetches head and start commits for affected pull requests.
            # That allows us to correctly assign diffs and commits to merge requests.
            fetch_missing_commits(pull_requests)

            pull_requests.each do |pull_request|
              job_waiter.jobs_remaining = Gitlab::Cache::Import::Caching.increment(job_waiter_remaining_cache_key)

              next if already_processed?(pull_request)

              job_delay = calculate_job_delay(job_waiter.jobs_remaining)

              sidekiq_worker_class.perform_in(job_delay, project.id, pull_request.to_hash, job_waiter.key)

              mark_as_processed(pull_request)
            end

            page += 1
            page_counter.set(page)
          end

          page_counter.expire!

          job_waiter
        end

        private

        def fetch_missing_commits(pull_requests)
          commits_to_fetch = pull_requests.filter_map do |pull_request|
            next if already_processed?(pull_request)
            next unless pull_request.merged? || pull_request.closed?

            [].tap do |commits|
              source_sha = pull_request.source_branch_sha
              target_sha = pull_request.target_branch_sha

              existing_commits = repo.commits_by(oids: [source_sha, target_sha]).map(&:sha)

              commits << source_branch_commit(source_sha, pull_request) unless existing_commits.include?(source_sha)
              commits << target_branch_commit(target_sha) unless existing_commits.include?(target_sha)
            end
          end.flatten

          return if commits_to_fetch.blank?

          project.repository.fetch_remote(project.import_url, refmap: commits_to_fetch, prune: false)
        rescue Gitlab::Git::CommandError => e
          # When we try to fetch commit from the submodule, then the process might fail
          # with "unadvertised object" error. We are going to ignore it, to unblock the import
          track_import_failure!(project, exception: e) unless e.message.include?('unadvertised object')
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

        def repo
          @repo ||= project.repository
        end

        def ref_path(pull_request)
          "refs/#{Repository::REF_MERGE_REQUEST}/#{pull_request.iid}/head"
        end

        def source_branch_commit(source_branch_sha, pull_request)
          [source_branch_sha, ':', ref_path(pull_request)].join
        end

        def target_branch_commit(target_branch_sha)
          [target_branch_sha, ':refs/keep-around/', target_branch_sha].join
        end

        # To avoid overloading Gitaly, we use a smaller limit for pull requests than the one defined in the
        # application settings.
        def concurrent_import_jobs_limit
          # Reduce fetch limit (from 100) to avoid Gitlab::Git::ResourceExhaustedError
          50
        end
      end
    end
  end
end
