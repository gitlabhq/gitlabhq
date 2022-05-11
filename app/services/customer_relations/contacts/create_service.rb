# frozen_string_literal: true

module CustomerRelations
  module Contacts
    class CreateService < BaseService
      def execute
        return error_no_permissions unless allowed?
        return error_organization_invalid unless organization_valid?

        contact = Contact.create(params.merge(group_id: group.id))
        return error_creating(contact) unless contact.persisted?

        ServiceResponse.success(payload: contact)
      end

      private

      def error_creating(contact)
        error(contact&.errors&.full_messages || 'Failed to create contact')
      end
    end
  end
end
