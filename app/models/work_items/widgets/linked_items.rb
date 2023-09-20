# frozen_string_literal: true

module WorkItems
  module Widgets
    class LinkedItems < Base
      delegate :linked_work_items, to: :work_item
    end
  end
end
