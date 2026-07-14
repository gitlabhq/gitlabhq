# frozen_string_literal: true

module MergeRequests
  class PushedBranchesService < MergeRequests::BaseService
    include ::Gitlab::Utils::StrongMemoize

    # rubocop: disable CodeReuse/ActiveRecord -- pluck requires ActiveRecord query methods
    def all_branches
      return [] if branch_names.blank?

      source_branches = project.source_of_merge_requests.open_and_closed
        .from_source_branches(branch_names).pluck(:source_branch)

      target_branches = project.merge_requests.opened
        .by_target_branch(branch_names).distinct.pluck(:target_branch)

      source_branches.concat(target_branches).to_set
    end

    def open_source_branches
      return [] if branch_names.blank?

      project.source_of_merge_requests
        .opened
        .from_source_branches(branch_names)
        .pluck(:source_branch)
        .to_set
    end
    strong_memoize_attr :open_source_branches

    # rubocop: enable CodeReuse/ActiveRecord

    private

    def branch_names
      params[:changes].map do |change|
        Gitlab::Git.branch_name(change[:ref])
      end.compact
    end
    strong_memoize_attr :branch_names
  end
end
