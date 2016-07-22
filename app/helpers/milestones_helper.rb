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

  # Returns count of milestones for different states
  # Uses explicit hash keys as the 'opened' state URL params differs from the db value 
  # and we need to add the total
  def milestone_counts(project:)
    counts = @project.milestones.reorder(nil).group(:state).count()
    {
      opened: counts['active'],
      closed: counts['closed'],
      all: counts['active'] + counts['closed']
    }
  end

  def milestone_progress_bar(milestone)
    options = {
      class: 'progress-bar progress-bar-success',
      style: "width: #{milestone.percent_complete(current_user)}%;"
    }

    content_tag :div, class: 'progress' do
      content_tag :div, nil, options
    end
  end

  def milestones_filter_dropdown_path
    if @project
      namespace_project_milestones_path(@project.namespace, @project, :json)
    else
      dashboard_milestones_path(:json)
    end
  end

  def milestone_remaining_days(milestone)
    if milestone.expired?
      content_tag(:strong, 'Past due')
    elsif milestone.due_date
      days    = milestone.remaining_days
      content = content_tag(:strong, days)
      content << " #{'day'.pluralize(days)} remaining"
    end
  end
end
