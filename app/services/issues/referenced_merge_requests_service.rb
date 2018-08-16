# frozen_string_literal: true

module Issues
  class ReferencedMergeRequestsService < Issues::BaseService
    def execute(issue)
      [
        sort_by_iid(referenced_merge_requests(issue)),
        sort_by_iid(closed_by_merge_requests(issue))
      ]
    end

    def referenced_merge_requests(issue)
      ext = issue.all_references(current_user)

      issue.notes_with_associations.each do |object|
        object.all_references(current_user, extractor: ext)
      end

      merge_requests = ext.merge_requests.sort_by(&:iid)

      cross_project_filter = -> (merge_requests) do
        merge_requests.select { |mr| mr.target_project == project }
      end

      Ability.merge_requests_readable_by_user(
        merge_requests,
        current_user,
        filters: {
          read_cross_project: cross_project_filter
        }
      )
    end

    def closed_by_merge_requests(issue)
      return [] unless issue.open?

      ext = issue.all_references(current_user)

      issue.notes.system.each do |note|
        note.all_references(current_user, extractor: ext)
      end

      merge_requests = ext.merge_requests.select(&:open?)

      return [] if merge_requests.empty?

      ids = MergeRequestsClosingIssues.where(merge_request_id: merge_requests.map(&:id), issue_id: issue.id).pluck(:merge_request_id)
      merge_requests.select { |mr| mr.id.in?(ids) }
    end

    private

    def sort_by_iid(merge_requests)
      Gitlab::IssuableSorter.sort(project, merge_requests) { |mr| mr.iid.to_s }
    end
  end
end
