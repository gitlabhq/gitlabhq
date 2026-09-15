# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class PullRequestsImporter
        include ParallelScheduling

        # Cannot exceed BitBucket Server's maximum page limit (1000)
        # https://confluence.atlassian.com/bitbucketserver/configuration-properties-776640155.html#Configurationproperties-Paging
        PER_PAGE = 100

        MAX_REFS_PER_FETCH = 50

        def execute
          page = page_counter.current

          loop do
            log_info(
              import_stage: 'import_pull_requests',
              message: "importing page #{page} using batch-size #{PER_PAGE}"
            )

            pull_requests = client.pull_requests(
              project_key, repository_slug, page_offset: page, limit: PER_PAGE
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
              next if already_processed?(pull_request)

              job_delay = calculate_job_delay(enqueued_job_counter)

              sidekiq_worker_class.perform_in(job_delay, project.id, pull_request.to_hash, job_waiter.key)

              self.enqueued_job_counter += 1

              job_waiter.jobs_remaining = Gitlab::Cache::Import::Caching.increment(job_waiter_remaining_cache_key)

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

          # Fetch missing commits in batches to avoid overloading Gitaly. Each batch is rescued
          # independently so a failure fetching one batch doesn't prevent the rest from being fetched.
          commits_to_fetch.each_slice(MAX_REFS_PER_FETCH) do |refs|
            fetch_commits(refs)
          end
        end

        def fetch_commits(refs)
          project.repository.fetch_remote(project.unsafe_import_url, refmap: refs, prune: false)
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

        # To avoid overloading Gitaly, pull request import concurrency is controlled by its own
        # setting, separate from the general Bitbucket Server import jobs limit.
        def concurrent_import_jobs_limit
          Gitlab::CurrentSettings.concurrent_pull_request_import_jobs_limit
        end
      end
    end
  end
end
