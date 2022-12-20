# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class AlertParser < BaseParser
      self.reference_type = :alert

      def self.reference_class
        AlertManagement::Alert
      end

      def references_relation
        AlertManagement::Alert
      end

      private

      def can_read_reference?(user, project, node)
        can?(user, :read_alert_management_alert, project)
      end
    end
  end
end
