# frozen_string_literal: true

module WorkItems
  module Callbacks
    class CrmContacts < Base
      OPERATION_MODES = {
        'APPEND' => :add_ids,
        'REMOVE' => :remove_ids,
        'REPLACE' => :replace_ids
      }.freeze

      def after_save
        return clear_contacts if excluded_in_new_type?

        set_contacts
      end

      private

      def clear_contacts
        return unless work_item.customer_relations_contact_ids.present?

        call_service({ replace_ids: [] })
      end

      def set_contacts
        return unless params.present?

        contact_ids = params[:contact_ids]
        return if contact_ids.nil?
        return if operation_mode_attribute.nil?
        return if work_item.customer_relations_contact_ids.sort == contact_ids.sort

        raise_error(unsupported_work_item_message) if group.nil?
        raise_error(feature_disabled_message) unless feature_enabled?

        call_service({ operation_mode_attribute => contact_ids })
      end

      def call_service(params)
        response = ::Issues::SetCrmContactsService.new(
          container: work_item.resource_parent,
          current_user: current_user,
          params: params
        ).execute(work_item)

        raise_error(response.message) unless response.success?
      end

      def feature_enabled?
        group&.crm_enabled?
      end

      def group
        @group ||= work_item.resource_parent.crm_group
      end

      def operation_mode_attribute
        @operation_mode_attribute = OPERATION_MODES[params[:operation_mode] || 'REPLACE']
      end

      def feature_disabled_message
        _('Feature disabled')
      end

      def unsupported_work_item_message
        _('Work item not supported')
      end
    end
  end
end
