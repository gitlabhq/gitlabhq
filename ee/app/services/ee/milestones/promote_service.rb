module EE
  module Milestones
    module PromoteService
      # rubocop: disable CodeReuse/ActiveRecord
      def update_children(group_milestone, milestone_ids)
        boards = ::Board.where(project_id: group_project_ids, milestone_id: milestone_ids)

        boards.update_all(milestone_id: group_milestone.id)

        super
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
