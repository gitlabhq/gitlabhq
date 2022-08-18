# frozen_string_literal: true

module WorkItems
  module Widgets
    class StartAndDueDate < Base
      delegate :start_date, :due_date, to: :work_item
    end
  end
end
