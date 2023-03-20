# frozen_string_literal: true

module WorkItems
  module Widgets
    class Notifications < Base
      delegate :subscribed?, to: :work_item
    end
  end
end
