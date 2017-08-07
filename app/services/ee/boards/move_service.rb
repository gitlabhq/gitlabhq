module EE
  module Boards
    module MoveService
      def remove_label_ids
        label_ids =
          if moving_to_list.movable?
            moving_from_list.label_id
          elsif board.is_group_board?
            Label.on_group_boards(parent.id).pluck(:label_id)
          else
            Label.on_project_boards(parent.id).pluck(:label_id)
          end

        Array(label_ids).compact
      end
    end
  end
end
