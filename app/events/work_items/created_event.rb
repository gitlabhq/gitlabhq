# frozen_string_literal: true

module WorkItems
  class CreatedEvent < BaseEvent
    event_type :created

    class << self
      def build(work_item:, current_user:)
        build_for_work_item(
          work_item: work_item,
          current_user: current_user
        )
      end
    end
  end
end
