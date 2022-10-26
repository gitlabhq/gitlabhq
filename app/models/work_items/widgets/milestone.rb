# frozen_string_literal: true

module WorkItems
  module Widgets
    class Milestone < Base
      delegate :milestone, to: :work_item
    end
  end
end
