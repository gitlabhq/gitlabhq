module MilestonesHelper
  def milestones_filter_path(opts = {})
    if @project
      namespace_project_milestones_path(@project.namespace, @project, opts)
    elsif @group
      group_milestones_path(@group, opts)
    else
      dashboard_milestones_path(opts)
    end
  end

  def milestone_progress_bar(milestone)
    options = {
      class: 'progress-bar progress-bar-success',
      style: "width: #{milestone.percent_complete}%;"
    }

    content_tag :div, class: 'progress' do
      content_tag :div, nil, options
    end
  end

  def projects_milestones_options
    milestones =
      if @project
        @project.milestones
      else
        Milestone.where(project_id: @projects)
      end.active

    grouped_milestones = Milestones::GroupService.new(milestones).execute
    grouped_milestones.unshift(Milestone::None)
    grouped_milestones.unshift(Milestone::Any)

    options_from_collection_for_select(grouped_milestones, 'name', 'title', params[:milestone_title])
  end
end
