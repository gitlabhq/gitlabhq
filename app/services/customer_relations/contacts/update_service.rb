# frozen_string_literal: true

module CustomerRelations
  module Contacts
    class UpdateService < BaseService
      def execute(contact)
        return error_no_permissions unless allowed?

        handle_active_param
        return error_updating(contact) unless contact.update(params)

        ServiceResponse.success(payload: contact)
      end

      private

      def handle_active_param
        return if params[:active].nil?

        active = params.delete(:active)
        params[:state] = active ? 'active' : 'inactive'
      end

      def error_no_permissions
        error('You have insufficient permissions to update a contact for this group')
      end

      def error_updating(contact)
        error(contact&.errors&.full_messages || 'Failed to update contact')
      end
    end
  end
end
