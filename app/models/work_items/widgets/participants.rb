# frozen_string_literal: true

module WorkItems
  module Widgets
    class Participants < Base
      delegate :participants, :visible_participants, to: :work_item
    end
  end
end
