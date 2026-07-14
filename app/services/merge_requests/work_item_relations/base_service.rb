# frozen_string_literal: true

module MergeRequests
  module WorkItemRelations
    class BaseService
      include Gitlab::Allowable

      # Maximum number of work item relations a single request may create or remove.
      MAX_RELATIONS = 100

      def initialize(merge_request:, current_user:)
        @merge_request = merge_request
        @current_user = current_user
      end

      private

      attr_reader :merge_request, :current_user

      def authorized?
        can?(current_user, required_permission, merge_request)
      end

      # The granular permission a subclass requires on the merge request
      # (e.g. :create_merge_request_work_item_relation).
      def required_permission
        raise NotImplementedError, "#{self.class} must implement #required_permission"
      end

      def forbidden_response
        ServiceResponse.error(
          message: _('You are not allowed to manage work item relations for this merge request.'),
          reason: :forbidden
        )
      end

      def too_many_relations_response
        ServiceResponse.error(
          message: format(_('Cannot process more than %{max} work item relations at once.'), max: MAX_RELATIONS),
          reason: :bad_request
        )
      end
    end
  end
end
