# frozen_string_literal: true

module MergeRequests
  module WorkItemRelations
    # Persists user-created MR <-> Work Item relations on
    # merge_requests_closing_issues. Authorizes the MR-level ability once, then
    # filters to the work items the user can actually read.
    #
    # Idempotent: an existing (merge_request, issue, link_type) row is reused,
    # not duplicated -- including when the row was inserted concurrently
    # (RecordNotUnique) or already exists with a different provenance (e.g. an
    # auto-derived `Closes #N` row). Work items that genuinely cannot be linked
    # are reported in the response payload under :errors rather than silently
    # dropped.
    class CreateService < BaseService
      def initialize(merge_request:, current_user:, target_work_items:, link_type: :related)
        super(merge_request: merge_request, current_user: current_user)

        @target_work_items = target_work_items
        @link_type = link_type
      end

      def execute
        return forbidden_response unless authorized?
        return mentioned_not_allowed_response if link_type.to_s == 'mentioned'
        return too_many_relations_response if target_work_items.size > MAX_RELATIONS

        readable_work_items = readable_work_items_for(target_work_items)

        if readable_work_items.empty?
          return ServiceResponse.error(
            message: _('No work items found that you have permission to link.'),
            reason: :unprocessable_entity
          )
        end

        relations = []
        errors = []

        readable_work_items.each do |work_item|
          relation, error = upsert_relation(work_item)

          relations << relation if relation
          errors << error if error
        end

        # Every readable work item failed to link -- surface it as an error
        # rather than a success with an empty result.
        if relations.empty?
          return ServiceResponse.error(
            message: _('No work items could be linked.'),
            payload: { work_item_relations: [], errors: errors },
            reason: :unprocessable_entity
          )
        end

        ServiceResponse.success(payload: { work_item_relations: relations, errors: errors })
      end

      private

      attr_reader :target_work_items, :link_type

      def required_permission
        :create_merge_request_work_item_relation
      end

      def mentioned_not_allowed_response
        ServiceResponse.error(
          message: _('Mentioned relations are managed automatically and cannot be created.'),
          reason: :bad_request
        )
      end

      # The work items, among the targets, that the current user can read --
      # resolved in a single authorized query via the finder rather than a
      # per-item permission check. Guards the empty case because the finder
      # treats a blank `ids` as "no filter" and would return every work item.
      def readable_work_items_for(work_items)
        ids = work_items.map(&:id)
        return WorkItem.none if ids.empty?

        WorkItems::WorkItemsFinder.new(current_user, ids: ids).execute
      end

      # Returns [relation, nil] when the relation is persisted (created, reused,
      # or already present under any provenance) and [nil, message] when the
      # work item genuinely could not be linked.
      def upsert_relation(work_item)
        # rubocop:disable CodeReuse/ActiveRecord -- thin find-or-initialize scoped to this MR's user-created
        # relations; equivalent logic would otherwise be duplicated in the model. Scoping to user_created keeps
        # auto-derived `Closes #N` rows (from_mr_description: true) from being matched and silently converted.
        relation = merge_request.merge_request_issues.user_created.find_or_initialize_by(
          issue_id: work_item.id,
          link_type: link_type
        )
        # rubocop:enable CodeReuse/ActiveRecord

        relation.from_mr_description = false
        relation.project_id = merge_request.project_id

        return [relation, nil] if relation.save

        # The save failed. If the (merge_request, issue, link_type) link already
        # exists -- including an auto-derived closes row -- the request is
        # already satisfied, so reuse it. Otherwise surface the reason.
        existing = existing_relation(work_item)
        return [existing, nil] if existing

        [nil, link_failure_message(work_item, relation)]
      rescue ActiveRecord::RecordNotUnique
        # A concurrent request inserted the same row between our lookup and the
        # INSERT; it now exists, so reuse it (idempotent).
        [existing_relation(work_item), nil]
      end

      def existing_relation(work_item)
        # rubocop:disable CodeReuse/ActiveRecord -- scoped existence check on this MR's relations
        merge_request.merge_request_issues.find_by(issue_id: work_item.id, link_type: link_type)
        # rubocop:enable CodeReuse/ActiveRecord
      end

      def link_failure_message(work_item, relation)
        format(
          _('Unable to link %{work_item_reference}: %{errors}'),
          work_item_reference: work_item.to_reference,
          errors: relation.errors.full_messages.to_sentence
        )
      end
    end
  end
end
