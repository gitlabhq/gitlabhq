module EE
  module Boards
    module Lists
      module CreateService
        def available_labels_for(board)
          if board.is_group_board?
            parent.labels.find(params[:label_id])
          else
            super
          end
        end
      end
    end
  end
end
