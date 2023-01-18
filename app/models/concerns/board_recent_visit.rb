# frozen_string_literal: true

module BoardRecentVisit
  extend ActiveSupport::Concern

  class_methods do
    def visited!(user, board)
      find_or_create_by(
        "user" => user,
        board_parent_relation => board.resource_parent,
        board_relation => board
      ).tap(&:touch)
    rescue ActiveRecord::RecordNotUnique
      retry
    end

    def latest(user, parent, count: nil)
      visits = by_user_parent(user, parent).order(updated_at: :desc)
      visits = visits.preload(board_relation)

      visits.first(count)
    end

    def board_relation
      :board
    end

    def board_parent_relation
      raise NotImplementedError
    end
  end
end
