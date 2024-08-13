# frozen_string_literal: true

module WorkItems
  module ClosingMergeRequests
    class CreateService
      ResourceNotAvailable = Class.new(StandardError)

      def initialize(current_user:, work_item:, merge_request_reference:, namespace_path: nil)
        @current_user = current_user
        @work_item = work_item
        @merge_request_reference = merge_request_reference
        @namespace_path = namespace_path
      end

      def execute
        raise ResourceNotAvailable, 'Cannot update work item' unless @current_user.can?(:update_work_item, @work_item)

        if @work_item.get_widget(:development).blank?
          return ServiceResponse.error(message: _('Development widget is not enabled for this work item type'))
        end

        merge_request = merge_request_from_reference
        raise ResourceNotAvailable, 'Merge request not available' if merge_request.blank?

        mr_closing_issue = MergeRequestsClosingIssues.new(
          merge_request: merge_request,
          issue_id: @work_item.id,
          from_mr_description: false
        )

        if mr_closing_issue.save
          GraphqlTriggers.work_item_updated(@work_item)

          ServiceResponse.success(payload: { merge_request_closing_issue: mr_closing_issue })
        else
          ServiceResponse.error(message: mr_closing_issue.errors.full_messages)
        end
      end

      private

      def merge_request_from_reference
        parent = parent_from_path

        extractor = if parent.is_a?(Project)
                      ::Gitlab::ReferenceExtractor.new(parent, @current_user)
                    else
                      ::Gitlab::ReferenceExtractor.new(nil, @current_user)
                    end

        extractor.analyze(@merge_request_reference, extractor_params_for(parent))
        extractor.merge_requests.first
      end

      def parent_from_path
        parent = Routable.find_by_full_path(@namespace_path)
        return parent if parent.present?

        # We fallback to the work item's parent as reference extractor always needs a parent to work
        @work_item.project || @work_item.namespace
      end

      def extractor_params_for(parent)
        if parent.is_a?(Group)
          { group: parent }
        else
          {}
        end
      end
    end
  end
end
