# frozen_string_literal: true

module Issues
  class ReferencedMergeRequestsService < Issues::BaseService
    def execute(issue)
      referenced = referenced_merge_requests(issue)
      closed_by = closed_by_merge_requests(issue)
      preloader = ActiveRecord::Associations::Preloader.new

      preloader.preload(referenced + closed_by,
                        head_pipeline: { project: [:route, { namespace: :route }] })

      [sort_by_iid(referenced), sort_by_iid(closed_by)]
    end

    def referenced_merge_requests(issue)
      merge_requests = extract_merge_requests(issue)

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

      merge_requests = extract_merge_requests(issue, filter: :system).select(&:open?)

      return [] if merge_requests.empty?

      ids = MergeRequestsClosingIssues.where(merge_request_id: merge_requests.map(&:id), issue_id: issue.id).pluck(:merge_request_id)
      merge_requests.select { |mr| mr.id.in?(ids) }
    end

    private

    def extract_merge_requests(issue, filter: nil)
      ext = issue.all_references(current_user)
      notes = issue_notes(issue)
      notes = notes.select(&filter) if filter

      notes.each do |note|
        note.all_references(current_user, extractor: ext)
      end

      ext.merge_requests
    end

    def issue_notes(issue)
      @issue_notes ||= {}
      @issue_notes[issue] ||= issue.notes.includes(:author)
    end

    def sort_by_iid(merge_requests)
      Gitlab::IssuableSorter.sort(project, merge_requests) { |mr| mr.iid.to_s }
    end
  end
end
