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

      def organization_valid?
        return true unless params[:organization_id]

        organization = Organization.find(params[:organization_id])
        organization.group_id == group.id
      rescue ActiveRecord::RecordNotFound
        false
      end

      def error_organization_invalid
        error('The specified organization was not found or does not belong to this group')
      end

      def error_no_permissions
        error('You have insufficient permissions to create a contact for this group')
      end

      def error_creating(contact)
        error(contact&.errors&.full_messages || 'Failed to create contact')
      end
    end
  end
end
