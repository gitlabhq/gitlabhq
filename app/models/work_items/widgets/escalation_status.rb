# frozen_string_literal: true

module WorkItems
  module Widgets
    class EscalationStatus < Base
      def escalation_status
        work_item.escalation_status&.status_name
      end
    end
  end
end
