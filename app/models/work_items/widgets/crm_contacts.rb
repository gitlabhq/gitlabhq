# frozen_string_literal: true

module WorkItems
  module Widgets
    class CrmContacts < Base
      delegate :customer_relations_contacts, to: :work_item

      def self.quick_action_commands
        [:add_contacts, :remove_contacts]
      end

      def self.quick_action_params
        [:contact_emails]
      end
    end
  end
end
