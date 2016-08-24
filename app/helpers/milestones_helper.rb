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
  def milestone_counts(milestones)
    counts = milestones.reorder(nil).group(:state).count

    {
      opened: counts['active'] || 0,
      closed: counts['closed'] || 0,
      all: counts.values.sum || 0
    }
  end

  # Show 'active' class if provided GET param matches check
  # `or_blank` allows the function to return 'active' when given an empty param
  # Could be refactored to be simpler but that may make it harder to read
  def milestone_class_for_state(param, check, match_blank_param = false)
    if match_blank_param
      'active' if param.blank? || param == check
    else
      'active' if param == check
    end
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
