# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Labels < Base
        def before_create
          # set labels, e.g.
          # target_work_item.label_ids = # work_item.labels = target_work_item.labels
          # todo system notes for removed/not copied labels either here or in the after_create_copy?
        end

        def post_move_cleanup
          # do it
        end
      end
    end
  end
end
