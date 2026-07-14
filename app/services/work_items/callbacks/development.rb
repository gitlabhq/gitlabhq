# frozen_string_literal: true

module WorkItems
  module Callbacks
    class Development < Base
      # Validate inside the create transaction so an invalid link aborts creation.
      def before_create
        each_target_merge_request do |merge_request|
          unless can?(current_user, :create_merge_request_work_item_relation, merge_request)
            raise_error(
              format(
                _('You are not allowed to link this work item to merge request %{reference}.'),
                reference: merge_request.to_reference(full: true)
              )
            )
          end

          raise_error(_('Mentioned relations are managed automatically and cannot be created.')) if mentioned_link?
        end
      end

      def after_save_commit
        each_target_merge_request do |merge_request|
          result = ::MergeRequests::WorkItemRelations::CreateService.new(
            merge_request: merge_request,
            current_user: current_user,
            target_work_items: [work_item],
            link_type: link_type
          ).execute

          log_error(result.message) if result.error?
        end
      end

      private

      def each_target_merge_request
        return unless params.present? && params.key?(:merge_request_ids)
        return unless Feature.enabled?(:explicit_mr_work_item_relations, work_item.project)

        target_merge_requests.each do |merge_request|
          next unless Feature.enabled?(:explicit_mr_work_item_relations, merge_request.project)

          yield merge_request
        end
      end

      def target_merge_requests
        @target_merge_requests ||= MergeRequest.id_in(params[:merge_request_ids])
      end

      def link_type
        params[:link_type] || :related
      end

      def mentioned_link?
        ::MergeRequestsClosingIssues.link_types.fetch(link_type.to_s, nil) ==
          ::MergeRequestsClosingIssues.link_types[:mentioned]
      end
    end
  end
end
