module MilestonesHelper
  def milestones_filter_path(opts = {})
    if @project
      project_milestones_path(@project, opts)
    elsif @group
      group_milestones_path(@group, opts)
    else
      dashboard_milestones_path(opts)
    end
  end

  def milestones_label_path(opts = {})
    if @project
      project_issues_path(@project, opts)
    elsif @group
      issues_group_path(@group, opts)
    else
      issues_dashboard_path(opts)
    end
  end

  def milestones_browse_issuables_path(milestone, state: nil, type:)
    opts = { milestone_title: milestone.title, state: state }

    if @project
      polymorphic_path([@project.namespace.becomes(Namespace), @project, type], opts)
    elsif @group
      polymorphic_url([type, @group], opts)
    else
      polymorphic_url([type, :dashboard], opts)
    end
  end

  def milestone_issues_by_label_count(milestone, label, state:)
    issues = milestone.issues.with_label(label.title)
    issues =
      case state
      when :opened
        issues.opened
      when :closed
        issues.closed
      else
        raise ArgumentError, "invalid milestone state `#{state}`"
      end

    issues.size
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
    elsif param == check
      'active'
    else
      check
    end
  end

  def milestone_progress_bar(milestone)
    options = {
      class: 'progress-bar bg-success',
      style: "width: #{milestone.percent_complete(current_user)}%;"
    }

    content_tag :div, class: 'progress' do
      content_tag :div, nil, options
    end
  end

  def milestones_filter_dropdown_path
    project = @target_project || @project
    if project
      project_milestones_path(project, :json)
    elsif @group
      group_milestones_path(@group, :json)
    else
      dashboard_milestones_path(:json)
    end
  end

  def milestone_tooltip_title(milestone)
    if milestone.due_date
      [milestone.due_date.to_s(:medium), "(#{milestone_remaining_days(milestone)})"].join(' ')
    end
  end

  def milestone_remaining_days(milestone)
    if milestone.expired?
      content_tag(:strong, 'Past due')
    elsif milestone.upcoming?
      content_tag(:strong, 'Upcoming')
    elsif milestone.due_date
      time_ago = time_ago_in_words(milestone.due_date)
      content = time_ago.gsub(/\d+/) { |match| "<strong>#{match}</strong>" }
      content.slice!("about ")
      content << " remaining"
      content.html_safe
    elsif milestone.start_date && milestone.start_date.past?
      days    = milestone.elapsed_days
      content = content_tag(:strong, days)
      content << " #{'day'.pluralize(days)} elapsed"
      content.html_safe
    end
  end

  def milestone_date_range(milestone)
    if milestone.start_date && milestone.due_date
      "#{milestone.start_date.to_s(:medium)}–#{milestone.due_date.to_s(:medium)}"
    elsif milestone.due_date
      if milestone.due_date.past?
        "expired on #{milestone.due_date.to_s(:medium)}"
      else
        "expires on #{milestone.due_date.to_s(:medium)}"
      end
    elsif milestone.start_date
      if milestone.start_date.past?
        "started on #{milestone.start_date.to_s(:medium)}"
      else
        "starts on #{milestone.start_date.to_s(:medium)}"
      end
    end
  end

  def milestone_merge_request_tab_path(milestone)
    if @project
      merge_requests_project_milestone_path(@project, milestone, format: :json)
    elsif @group
      merge_requests_group_milestone_path(@group, milestone.safe_title, title: milestone.title, format: :json)
    else
      merge_requests_dashboard_milestone_path(milestone, title: milestone.title, format: :json)
    end
  end

  def milestone_participants_tab_path(milestone)
    if @project
      participants_project_milestone_path(@project, milestone, format: :json)
    elsif @group
      participants_group_milestone_path(@group, milestone.safe_title, title: milestone.title, format: :json)
    else
      participants_dashboard_milestone_path(milestone, title: milestone.title, format: :json)
    end
  end

  def milestone_labels_tab_path(milestone)
    if @project
      labels_project_milestone_path(@project, milestone, format: :json)
    elsif @group
      labels_group_milestone_path(@group, milestone.safe_title, title: milestone.title, format: :json)
    else
      labels_dashboard_milestone_path(milestone, title: milestone.title, format: :json)
    end
  end

  def group_milestone_route(milestone, params = {})
    params = nil if params.empty?

    if milestone.legacy_group_milestone?
      group_milestone_path(@group, milestone.safe_title, title: milestone.title, milestone: params)
    else
      group_milestone_path(@group, milestone.iid, milestone: params)
    end
  end
end
