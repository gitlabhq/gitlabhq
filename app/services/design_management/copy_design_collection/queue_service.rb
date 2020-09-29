# frozen_string_literal: true

# Service for setting the initial copy_state on the target DesignCollection
# and queuing a CopyDesignCollectionWorker.
module DesignManagement
  module CopyDesignCollection
    class QueueService
      def initialize(current_user, issue, target_issue)
        @current_user = current_user
        @issue = issue
        @target_issue = target_issue
        @target_design_collection = target_issue.design_collection
      end

      def execute
        return error('User cannot copy designs to issue') unless user_can_copy?
        return error('Target design collection copy state must be `ready`') unless target_design_collection.can_start_copy?

        target_design_collection.start_copy!

        DesignManagement::CopyDesignCollectionWorker.perform_async(current_user.id, issue.id, target_issue.id)

        ServiceResponse.success
      end

      private

      delegate :design_collection, to: :issue

      attr_reader :current_user, :issue, :target_design_collection, :target_issue

      def error(message)
        ServiceResponse.error(message: message)
      end

      def user_can_copy?
        current_user.can?(:read_design, issue) &&
          current_user.can?(:admin_issue, target_issue)
      end
    end
  end
end
