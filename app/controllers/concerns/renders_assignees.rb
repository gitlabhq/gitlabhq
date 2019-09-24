# frozen_string_literal: true

module RendersAssignees
  def preload_assignees_for_render(merge_request)
    merge_request.project.team.max_member_access_for_user_ids(merge_request.assignees.map(&:id))
  end
end
