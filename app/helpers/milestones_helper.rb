module MilestonesHelper
  def milestones_filter_path(opts = {})
    if @project
      project_milestones_path(@project, opts)
    elsif @group
      group_milestones_path(@group, opts)
    end
  end
end
