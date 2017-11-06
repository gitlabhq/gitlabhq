module EE
  module Milestones
    module PromoteService
      def update_children(group_milestone, milestone_ids)
        boards = ::Board.where(project_id: group_project_ids, milestone_id: milestone_ids)

        boards.update_all(milestone_id: group_milestone.id)

        super
      end
    end
  end
end
