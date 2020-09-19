# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class AlertParser < BaseParser
      self.reference_type = :alert

      def references_relation
        AlertManagement::Alert
      end

      private

      def can_read_reference?(user, alert, node)
        can?(user, :read_alert_management_alert, alert)
      end
    end
  end
end
