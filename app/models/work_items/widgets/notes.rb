# frozen_string_literal: true

module WorkItems
  module Widgets
    class Notes < Base
      delegate :notes, to: :work_item
      delegate_missing_to :work_item

      def declarative_policy_delegate
        work_item
      end
    end
  end
end
