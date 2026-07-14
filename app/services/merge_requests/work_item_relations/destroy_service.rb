# frozen_string_literal: true

module MergeRequests
  module WorkItemRelations
    # Removes user-created MR <-> Work Item relations by row id (batch).
    # Scoping the delete to the MR's own user_created rows means:
    #   - rows belonging to another merge request are silently ignored
    #     (the MR-level ability already gates access to this MR), and
    #   - auto-derived `Closes #N` rows (from_mr_description: true) are never
    #     deletable through this path.
    class DestroyService < BaseService
      def initialize(merge_request:, current_user:, ids:)
        super(merge_request: merge_request, current_user: current_user)

        @ids = Array(ids)
      end

      def execute
        return forbidden_response unless authorized?
        return too_many_relations_response if ids.size > MAX_RELATIONS

        removed_ids = delete_relations

        ServiceResponse.success(payload: { removed_ids: removed_ids })
      end

      private

      attr_reader :ids

      def required_permission
        :delete_merge_request_work_item_relation
      end

      def delete_relations
        # rubocop:disable CodeReuse/ActiveRecord -- scoped lookup/delete on this MR's user-created relations.
        candidates = merge_request.merge_request_issues.user_created.where(id: ids)
          .limit(MAX_RELATIONS).pluck(:id, :issue_id)
        # rubocop:enable CodeReuse/ActiveRecord

        # Only remove relations whose work item the user can actually read, so a
        # readable MR cannot be used to manage links to work items hidden from
        # the user (the `user_created` scope still protects auto-derived rows).
        readable_ids = readable_work_item_ids(candidates.map(&:last))
        removed_ids = candidates.select { |_id, issue_id| readable_ids.include?(issue_id) }.map(&:first)

        # rubocop:disable CodeReuse/ActiveRecord -- delete by primary key on this MR's relations.
        merge_request.merge_request_issues.where(id: removed_ids).delete_all
        # rubocop:enable CodeReuse/ActiveRecord

        removed_ids
      end

      def readable_work_item_ids(work_item_ids)
        return [] if work_item_ids.empty?

        # rubocop:disable CodeReuse/ActiveRecord -- bounded (<= MAX_RELATIONS) readability filter via the finder.
        WorkItems::WorkItemsFinder.new(current_user, ids: work_item_ids).execute.limit(MAX_RELATIONS).pluck(:id)
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
