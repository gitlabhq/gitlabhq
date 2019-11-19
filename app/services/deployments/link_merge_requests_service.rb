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
      return unless deployment.success?

      if (prev = deployment.previous_environment_deployment)
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
