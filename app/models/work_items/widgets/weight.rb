# frozen_string_literal: true

module WorkItems
  module Widgets
    class Weight < Base
      delegate :weight, to: :work_item
    end
  end
end
