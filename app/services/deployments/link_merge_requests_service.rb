# frozen_string_literal: true

module Deployments
  # Service class for linking merge requests to deployments.
  class LinkMergeRequestsService
    attr_reader :deployment

    # The number of commits per query for which to find merge requests.
    COMMITS_PER_QUERY = 5_000

    def initialize(deployment)
      @deployment = deployment
    end

    def execute
      # Review apps have the environment type set (e.g. to `review`, though the
      # exact value may differ). We don't want to link merge requests to review
      # app deployments, as this is not useful.
      return if deployment.environment.environment_type

      # This service is triggered by a Sidekiq worker, which only runs when a
      # deployment is successful. We add an extra check here in case we ever
      # call this service elsewhere and forget to check the status there.
      #
      # The reason we only want to link successful deployments is as follows:
      # when we link a merge request, we don't link it to future deployments for
      # the same environment. If we were to link an MR to a failed deploy, we
      # wouldn't be able to later on link it to a successful deploy (e.g. after
      # the deploy is retried).
      #
      # In addition, showing failed deploys in the UI of a merge request isn't
      # useful to users, as they can't act upon the information in any
      # meaningful way (i.e. they can't just retry the deploy themselves).
      return unless deployment.success?

      if (prev = deployment.previous_deployment)
        link_merge_requests_for_range(prev.sha, deployment.sha)
      else
        # When no previous deployment is found we fall back to linking all merge
        # requests merged into the deployed branch. This will not always be
        # accurate, but it's better than having no data.
        #
        # We can't use the first commit in the repository as a base to compare
        # to, as this will not scale to large repositories. For example, GitLab
        # itself has over 150 000 commits.
        link_all_merged_merge_requests
      end
    end

    def link_merge_requests_for_range(from, to)
      commits = project
        .repository
        .commits_between(from, to)
        .map(&:id)

      # For some projects the list of commits to deploy may be very large. To
      # ensure we do not end up running SQL queries with thousands of WHERE IN
      # values, we run one query per a certain number of commits.
      #
      # In most cases this translates to only a single query. For very large
      # deployment we may end up running a handful of queries to get and insert
      # the data.
      commits.each_slice(COMMITS_PER_QUERY) do |slice|
        merge_requests =
          project.merge_requests.merged.by_merge_commit_sha(slice)

        deployment.link_merge_requests(merge_requests)

        # The cherry picked commits are tracked via `notes.commit_id`
        # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/22209
        #
        # NOTE: cross-joining `merge_requests` table and `notes` table could
        # result in very poor performance because PG planner often uses an
        # inappropriate index.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/321032.
        mr_ids = project.notes.cherry_picked_merge_requests(slice)
        picked_merge_requests = project.merge_requests.id_in(mr_ids)

        deployment.link_merge_requests(picked_merge_requests)
      end
    end

    def link_all_merged_merge_requests
      merge_requests =
        project.merge_requests.merged.by_target_branch(deployment.ref)

      deployment.link_merge_requests(merge_requests)
    end

    private

    def project
      deployment.project
    end
  end
end
