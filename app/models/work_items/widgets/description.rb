# frozen_string_literal: true

module WorkItems
  module Widgets
    class Description < Base
      delegate :description, to: :work_item
    end
  end
end
