# frozen_string_literal: true

module WorkItems
  module Widgets
    class Labels < Base
      delegate :labels, to: :work_item
      delegate :allows_scoped_labels?, to: :work_item
    end
  end
end
