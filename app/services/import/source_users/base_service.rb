# frozen_string_literal: true

module Import
  module SourceUsers
    class BaseService
      private

      attr_reader :import_source_user, :current_user

      def error_invalid_permissions
        ServiceResponse.error(
          message: s_('Import|You have insufficient permissions to update the import source user'),
          reason: :forbidden
        )
      end

      def error_invalid_status
        ServiceResponse.error(
          message: s_('Import|Import source user has an invalid status for this operation'),
          reason: :invalid_status,
          payload: import_source_user
        )
      end

      def send_user_reassign_email
        Notify.import_source_user_reassign(import_source_user.id).deliver_now
      end
    end
  end
end
