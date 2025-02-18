# frozen_string_literal: true

module WorkItems
  module Widgets
    class Labels < Base
      delegate :labels, to: :work_item
      delegate :allows_scoped_labels?, to: :work_item

      class << self
        def quick_action_commands
          [:label, :labels, :relabel, :remove_label, :unlabel]
        end

        def quick_action_params
          [:add_label_ids, :remove_label_ids, :label_ids]
        end

        def sorting_keys
          {
            label_priority_asc: {
              description: 'Label priority by ascending order.'
            },
            label_priority_desc: {
              description: 'Label priority by descending order.'
            }
          }
        end
      end
    end
  end
end
