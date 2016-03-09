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

  def milestones_label_path(opts = {})
    if @project
      namespace_project_issues_path(@project.namespace, @project, opts)
    elsif @group
      issues_group_path(@group, opts)
    else
      issues_dashboard_path(opts)
    end
  end

  def milestones_browse_issuables_path(milestone, type:)
    opts = { milestone_title: milestone.title }

    if @project
      polymorphic_path([@project.namespace.becomes(Namespace), @project, type], opts)
    elsif @group
      polymorphic_url([type, @group], opts)
    else
      polymorphic_url([type, :dashboard], opts)
    end
  end

  def milestone_issues_by_label_count(milestone, label, state:)
    milestone.issues.with_label(label.title).send(state).size
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

    epoch = DateTime.parse('1970-01-01')
    grouped_milestones = GlobalMilestone.build_collection(milestones)
    grouped_milestones = grouped_milestones.sort_by { |x| x.due_date.nil? ? epoch : x.due_date }
    grouped_milestones.unshift(Milestone::None)
    grouped_milestones.unshift(Milestone::Any)

    options_from_collection_for_select(grouped_milestones, 'name', 'title', params[:milestone_title])
  end

  def milestone_remaining_days(milestone)
    if milestone.expired?
      content_tag(:strong, 'expired')
    elsif milestone.due_date
      days    = milestone.remaining_days
      content = content_tag(:strong, days)
      content << " #{'day'.pluralize(days)} remaining"
    end
  end
end
