# frozen_string_literal: true

module WorkItems
  module Widgets
    class LinkedItems < Base
      delegate :related_issues, to: :work_item
    end
  end
end
