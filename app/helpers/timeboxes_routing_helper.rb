# frozen_string_literal: true

module TimeboxesRoutingHelper
  def milestone_path(milestone, *args)
    if milestone.group_milestone?
      group_milestone_path(milestone.group, milestone, *args)
    elsif milestone.project_milestone?
      project_milestone_path(milestone.project, milestone, *args)
    end
  end

  def milestone_url(milestone, *args)
    if milestone.group_milestone?
      group_milestone_url(milestone.group, milestone, *args)
    elsif milestone.project_milestone?
      project_milestone_url(milestone.project, milestone, *args)
    end
  end
end

TimeboxesRoutingHelper.prepend_mod_with('TimeboxesRoutingHelper')
