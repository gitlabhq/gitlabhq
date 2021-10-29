# frozen_string_literal: true

module CustomerRelations
  module Contacts
    class BaseService < ::BaseGroupService
      private

      def allowed?
        current_user&.can?(:admin_crm_contact, group)
      end

      def error(message)
        ServiceResponse.error(message: Array(message))
      end
    end
  end
end
