# frozen_string_literal: true

module WorkItems
  module Widgets
    class Severity < Base
      delegate :severity, to: :work_item
    end
  end
end
