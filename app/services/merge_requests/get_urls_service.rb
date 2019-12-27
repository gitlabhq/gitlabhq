# frozen_string_literal: true

module MergeRequests
  class GetUrlsService < BaseService
    attr_reader :project

    def initialize(project)
      @project = project
    end

    def execute(changes)
      return [] unless project&.printing_merge_request_link_enabled

      branches = get_branches(changes)
      merge_requests_map = opened_merge_requests_from_source_branches(branches)
      branches.map do |branch|
        existing_merge_request = merge_requests_map[branch]
        if existing_merge_request
          url_for_existing_merge_request(existing_merge_request)
        else
          url_for_new_merge_request(branch)
        end
      end
    end

    private

    def opened_merge_requests_from_source_branches(branches)
      merge_requests = MergeRequest.from_project(project).opened.from_source_branches(branches)
      merge_requests.index_by(&:source_branch)
    end

    def get_branches(changes)
      return [] if project.empty_repo?
      return [] unless project.merge_requests_enabled?

      changes_list = Gitlab::ChangesList.new(changes)
      changes_list.map do |change|
        next unless Gitlab::Git.branch_ref?(change[:ref])

        # Deleted branch
        next if Gitlab::Git.blank_ref?(change[:newrev])

        # Default branch
        branch_name = Gitlab::Git.branch_name(change[:ref])
        next if branch_name == project.default_branch

        branch_name
      end.compact
    end

    def url_for_new_merge_request(branch_name)
      merge_request_params = { source_branch: branch_name }
      url = Gitlab::Routing.url_helpers.project_new_merge_request_url(project, merge_request: merge_request_params)
      { branch_name: branch_name, url: url, new_merge_request: true }
    end

    def url_for_existing_merge_request(merge_request)
      target_project = merge_request.target_project
      url = Gitlab::Routing.url_helpers.project_merge_request_url(target_project, merge_request)
      { branch_name: merge_request.source_branch, url: url, new_merge_request: false }
    end
  end
end
