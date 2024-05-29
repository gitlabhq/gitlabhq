# frozen_string_literal: true

module WorkItems
  module ClosingMergeRequests
    class CreateService
      ResourceNotAvailable = Class.new(StandardError)

      def initialize(current_user:, work_item:, merge_request_reference:, namespace_path:)
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

        project = Project.find_by_full_path(@namespace_path)
        merge_request = merge_request_from_reference(project)
        raise ResourceNotAvailable, 'Merge request not available' if merge_request.blank?

        mr_closing_issue = MergeRequestsClosingIssues.new(
          merge_request: merge_request,
          issue_id: @work_item.id,
          from_mr_description: false
        )

        if mr_closing_issue.save
          ServiceResponse.success(payload: { merge_request_closing_issue: mr_closing_issue })
        else
          ServiceResponse.error(message: mr_closing_issue.errors.full_messages)
        end
      end

      private

      def merge_request_from_reference(project)
        extractor = ::Gitlab::ReferenceExtractor.new(project, @current_user)
        extractor.analyze(@merge_request_reference, {})

        extractor.references(:merge_request).first # rubocop:disable CodeReuse/ActiveRecord -- references is not AR method
      end
    end
  end
end
