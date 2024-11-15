# frozen_string_literal: true

# This service fetches all branches containing the current issue's ID, except for
# those with a merge request open referencing the current issue.
module Issues
  class RelatedBranchesService < Issues::BaseService
    def execute(issue)
      branch_names_with_mrs = branches_with_merge_request_for(issue)
      branches = branches_with_iid_of(issue).reject { |b| branch_names_with_mrs.include?(b[:name]) }

      branches.map { |branch| branch_data(branch) }
    end

    private

    def branch_data(branch)
      {
        name: branch[:name],
        pipeline_status: pipeline_status(branch),
        compare_path: branch_path(branch)
      }
    end

    def pipeline_status(branch)
      pipeline = project.latest_pipeline(branch[:name], branch[:target])
      pipeline.detailed_status(current_user) if can?(current_user, :read_pipeline, pipeline)
    end

    def branches_with_merge_request_for(issue)
      Issues::ReferencedMergeRequestsService
        .new(container: project, current_user: current_user)
        .referenced_merge_requests(issue)
        .map(&:source_branch)
    end

    def branches_with_iid_of(issue)
      branch_ref_regex = /\A#{Gitlab::Git::BRANCH_REF_PREFIX}#{issue.iid}-(?!\d+-stable)/i

      return [] unless project.repository.exists?

      project.repository.list_refs(
        [Gitlab::Git::BRANCH_REF_PREFIX + "#{issue.iid}-*"]
      ).each_with_object([]) do |ref, results|
        if ref.name.match?(branch_ref_regex)
          results << { name: ref.name.delete_prefix(Gitlab::Git::BRANCH_REF_PREFIX), target: ref.target }
        end
      end
    end

    def branch_path(branch)
      Gitlab::Routing.url_helpers.project_compare_path(project, from: project.default_branch, to: branch[:name])
    end
  end
end
