# frozen_string_literal: true

module WorkItems
  module Widgets
    class Milestone < Base
      delegate :milestone, to: :work_item

      class << self
        def quick_action_commands
          [:milestone, :remove_milestone]
        end

        def quick_action_params
          [:milestone_id]
        end

        def sorting_keys
          {
            milestone_due_asc: {
              description: 'Milestone due date by ascending order.'
            },
            milestone_due_desc: {
              description: 'Milestone due date by descending order.'
            }
          }
        end
      end
    end
  end
end
