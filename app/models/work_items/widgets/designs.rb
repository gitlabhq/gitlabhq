# frozen_string_literal: true

module WorkItems
  module Widgets
    class Designs < Base
      delegate :designs, :design_versions, :design_collection, to: :work_item
    end
  end
end
