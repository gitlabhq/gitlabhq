# frozen_string_literal: true

module Import
  module SourceUsers
    class BaseService
      private

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
    end
  end
end
