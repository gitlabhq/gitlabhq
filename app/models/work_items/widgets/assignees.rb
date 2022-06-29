# frozen_string_literal: true

module WorkItems
  module Widgets
    class Assignees < Base
      delegate :assignees, to: :work_item
      delegate :allows_multiple_assignees?, to: :work_item
    end
  end
end
