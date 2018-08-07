module Boards
  class MilestonesController < Boards::ApplicationController
    def index
      milestones_finder = Boards::MilestonesFinder.new(board, current_user)

      render json: MilestoneSerializer.new.represent(milestones_finder.execute)
    end
  end
end
