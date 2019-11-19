# frozen_string_literal: true

module MilestonesHelper
  include EntityDateHelper
  include Gitlab::Utils::StrongMemoize

  def milestone_status_string(milestone)
    if milestone.closed?
      _('Closed')
    elsif milestone.expired?
      _('Past due')
    elsif milestone.upcoming?
      _('Upcoming')
    else
      _('Open')
    end
  end

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
        raise ArgumentError, _("invalid milestone state `%{state}`") % { state: state }
      end

    issues.size
  end

  # Returns count of milestones for different states
  # Uses explicit hash keys as the 'opened' state URL params differs from the db value
  # and we need to add the total
  # rubocop: disable CodeReuse/ActiveRecord
  def milestone_counts(milestones)
    counts = milestones.reorder(nil).group(:state).count

    {
      opened: counts['active'] || 0,
      closed: counts['closed'] || 0,
      all: counts.values.sum || 0
    }
  end
  # rubocop: enable CodeReuse/ActiveRecord

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

  def milestone_progress_tooltip_text(milestone)
    has_issues = milestone.total_issues_count(current_user) > 0

    if has_issues
      [
        _('Progress'),
        _("%{percent}%% complete") % { percent: milestone.percent_complete(current_user) }
      ].join('<br />')
    else
      _('Progress')
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

  def milestone_time_for(date, date_type)
    title = date_type == :start ? "Start date" : "End date"

    if date
      time_ago = time_ago_in_words(date).sub("about ", "")
      state = if date.past?
                "ago"
              else
                "remaining"
              end

      content = [
        title,
        "<br />",
        date.to_s(:medium),
        "(#{time_ago} #{state})"
      ].join(" ")

      content.html_safe
    else
      title
    end
  end

  def milestone_issues_tooltip_text(milestone)
    issues = milestone.count_issues_by_state(current_user)

    return _("Issues") if issues.empty?

    content = []

    if issues["opened"]
      content << n_("1 open issue", "%{issues} open issues", issues["opened"]) % { issues: issues["opened"] }
    end

    if issues["closed"]
      content << n_("1 closed issue", "%{issues} closed issues", issues["closed"]) % { issues: issues["closed"] }
    end

    content.join('<br />').html_safe
  end

  def milestone_merge_requests_tooltip_text(milestone)
    merge_requests = milestone.merge_requests

    return _("Merge requests") if merge_requests.empty?

    content = []

    content << n_("1 open merge request", "%{merge_requests} open merge requests", merge_requests.opened.count) % { merge_requests: merge_requests.opened.count } if merge_requests.opened.any?
    content << n_("1 closed merge request", "%{merge_requests} closed merge requests", merge_requests.closed.count) % { merge_requests: merge_requests.closed.count } if merge_requests.closed.any?
    content << n_("1 merged merge request", "%{merge_requests} merged merge requests", merge_requests.merged.count) % { merge_requests: merge_requests.merged.count } if merge_requests.merged.any?

    content.join('<br />').html_safe
  end

  def milestone_releases_tooltip_text(milestone)
    count = milestone.releases.count

    return _("Releases") if count.zero?

    n_("%{releases} release", "%{releases} releases", count) % { releases: count }
  end

  def recent_releases_with_counts(milestone)
    total_count = milestone.releases.size
    return [[], 0, 0] if total_count == 0

    recent_releases = milestone.releases.recent.to_a
    more_count = total_count - recent_releases.size
    [recent_releases, total_count, more_count]
  end

  def milestone_tooltip_due_date(milestone)
    if milestone.due_date
      "#{milestone.due_date.to_s(:medium)} (#{remaining_days_in_words(milestone.due_date, milestone.start_date)})"
    else
      _('Milestone')
    end
  end

  def milestone_date_range(milestone)
    if milestone.start_date && milestone.due_date
      "#{milestone.start_date.to_s(:medium)}–#{milestone.due_date.to_s(:medium)}"
    elsif milestone.due_date
      if milestone.due_date.past?
        _("expired on %{milestone_due_date}") % { milestone_due_date: milestone.due_date.strftime('%b %-d, %Y') }
      else
        _("expires on %{milestone_due_date}") % { milestone_due_date: milestone.due_date.strftime('%b %-d, %Y') }
      end
    elsif milestone.start_date
      if milestone.start_date.past?
        _("started on %{milestone_start_date}") % { milestone_start_date: milestone.start_date.strftime('%b %-d, %Y') }
      else
        _("starts on %{milestone_start_date}") % { milestone_start_date: milestone.start_date.strftime('%b %-d, %Y') }
      end
    end
  end

  def milestone_tab_path(milestone, tab)
    if milestone.global_milestone?
      url_for(action: tab, title: milestone.title, format: :json)
    else
      url_for(action: tab, format: :json)
    end
  end

  def update_milestone_path(milestone, params = {})
    if milestone.project_milestone?
      project_milestone_path(milestone.project, milestone, milestone: params)
    else
      group_milestone_route(milestone, params)
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

  def group_or_project_milestone_path(milestone)
    params =
      if milestone.group_milestone?
        { milestone: { title: milestone.title } }
      else
        { title: milestone.title }
      end

    milestone_path(milestone.milestone, params)
  end

  def edit_milestone_path(milestone)
    if milestone.group_milestone?
      edit_group_milestone_path(milestone.group, milestone)
    elsif milestone.project_milestone?
      edit_project_milestone_path(milestone.project, milestone)
    end
  end

  def can_admin_project_milestones?
    strong_memoize(:can_admin_project_milestones) do
      can?(current_user, :admin_milestone, @project)
    end
  end

  def can_admin_group_milestones?
    strong_memoize(:can_admin_group_milestones) do
      can?(current_user, :admin_milestone, @project.group)
    end
  end
end

MilestonesHelper.prepend_if_ee('EE::MilestonesHelper')
