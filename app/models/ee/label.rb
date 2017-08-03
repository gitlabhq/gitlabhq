module EE
  module Label
    extend ActiveSupport::Concern

    prepended do
      scope :on_group_boards, ->(group_id) { with_lists_and_board.where(boards: { group_id: group_id }) }
    end
  end
end
