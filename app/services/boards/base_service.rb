module Boards
  class BaseService < ::BaseService
    # Parent can either a group or a project
    attr_accessor :parent, :current_user, :params

    def initialize(parent, user, params = {})
      @parent, @current_user, @params = parent, user, params.dup
    end

    def set_assignee
      assignee = User.find_by(id: params.delete(:assignee_id))
      params.merge!(assignee: assignee)
    end

    def set_milestone
      milestone_id = params[:milestone_id]

      return unless milestone_id

      return if [::Milestone::None.id,
                 ::Milestone::Upcoming.id,
                 ::Milestone::Started.id].include?(milestone_id)

      finder_params =
        case parent
        when Group
          { group_ids: [parent.id] }
        when Project
          { project_ids: [parent.id], group_ids: [parent.group&.id] }
        end

      milestone = MilestonesFinder.new(finder_params).find_by(id: milestone_id)

      params[:milestone_id] = milestone&.id
    end
  end
end
