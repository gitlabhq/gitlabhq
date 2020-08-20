# frozen_string_literal: true

module MergeRequests
  class PushedBranchesService < MergeRequests::BaseService
    include ::Gitlab::Utils::StrongMemoize

    # Skip moving this logic into models since it's too specific
    # rubocop: disable CodeReuse/ActiveRecord
    def execute
      return [] if branch_names.blank?

      source_branches = project.source_of_merge_requests.open_and_closed
        .from_source_branches(branch_names).pluck(:source_branch)

      target_branches = project.merge_requests.opened
        .by_target_branch(branch_names).distinct.pluck(:target_branch)

      source_branches.concat(target_branches).to_set
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def branch_names
      strong_memoize(:branch_names) do
        params[:changes].map do |change|
          Gitlab::Git.branch_name(change[:ref])
        end.compact
      end
    end
  end
end
