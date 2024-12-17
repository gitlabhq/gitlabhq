# frozen_string_literal: true

module TimeboxesHelper
  include EntityDateHelper
  include Gitlab::Utils::StrongMemoize

  def milestone_status_string(milestone)
    if milestone.closed?
      _('Closed')
    elsif milestone.expired?
      _('Expired')
    elsif milestone.upcoming?
      _('Upcoming')
    else
      _('Open')
    end
  end

  def milestone_badge_variant(milestone)
    if milestone.closed?
      :info
    elsif milestone.expired?
      :warning
    elsif milestone.upcoming?
      :neutral
    else
      :success
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

  def milestones_issues_path(opts = {})
    if @project
      project_issues_path(@project, opts)
    elsif @group
      issues_group_path(@group, opts)
    else
      issues_dashboard_path(opts)
    end
  end

  def milestones_browse_issuables_path(milestone, type:, state: nil)
    opts = { milestone_title: milestone.title, state: state }

    if @project
      polymorphic_path([@project, type], opts)
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

  def milestone_progress_tooltip_text(milestone)
    has_issues = milestone.total_issues_count > 0

    if has_issues
      [
        _('Progress'),
        _("%{percent}%% complete") % { percent: milestone.percent_complete }
      ].join('<br />')
    else
      _('Progress')
    end
  end

  def milestone_progress_bar(milestone)
    render Pajamas::ProgressComponent.new(
      value: milestone.percent_complete,
      variant: :primary
    )
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
        date.to_fs(:medium),
        "(#{time_ago} #{state})"
      ].join(" ")

      content.html_safe
    else
      title
    end
  end

  def milestone_issues_tooltip_text(milestone)
    total = milestone.total_issues_count
    opened = milestone.opened_issues_count
    closed = milestone.closed_issues_count

    return _("Issues") if total == 0

    content = []

    content << (n_("1 open issue", "%{issues} open issues", opened) % { issues: opened }) if opened > 0

    content << (n_("1 closed issue", "%{issues} closed issues", closed) % { issues: closed }) if closed > 0

    content.join('<br />').html_safe
  end

  def milestone_merge_requests_tooltip_text(milestone)
    merge_requests = milestone.merge_requests

    return _("Merge requests") if merge_requests.empty?

    content = []

    if merge_requests.opened.any?
      content << (
        n_(
          "1 open merge request", "%{merge_requests} open merge requests",
          merge_requests.opened.count
        ) % { merge_requests: merge_requests.opened.count }
      )
    end

    if merge_requests.closed.any?
      content << (
        n_(
          "1 closed merge request", "%{merge_requests} closed merge requests",
          merge_requests.closed.count
        ) % { merge_requests: merge_requests.closed.count }
      )
    end

    if merge_requests.merged.any?
      content << (
        n_(
          "1 merged merge request", "%{merge_requests} merged merge requests",
          merge_requests.merged.count
        ) % { merge_requests: merge_requests.merged.count }
      )
    end

    content.join('<br />').html_safe
  end

  def milestone_releases_tooltip_text(milestone)
    count = milestone.releases.count

    return _("Releases") if count == 0

    n_("%{releases} release", "%{releases} releases", count) % { releases: count }
  end

  def recent_releases_with_counts(milestone, user)
    total_count = milestone.releases.size
    return [[], 0, 0] if total_count == 0

    recent_releases = milestone.releases.recent.filter { |release| Ability.allowed?(user, :read_release, release) }
    more_count = total_count - recent_releases.size
    [recent_releases, total_count, more_count]
  end

  def milestone_releases_tooltip_list(releases, more_count = 0)
    list = releases.map(&:name).join(", ")
    list += format(_(", and %{number} more"), number: more_count) if more_count > 0
    list
  end

  def milestone_tooltip_due_date(milestone)
    if milestone.due_date
      "#{milestone.due_date.to_fs(:medium)} (#{remaining_days_in_words(milestone.due_date, milestone.start_date)})"
    else
      _('Milestone')
    end
  end

  def timebox_date_range(timebox)
    if timebox.start_date && timebox.due_date
      s_("DateRange|%{start_date}–%{end_date}") % {
        start_date: l(timebox.start_date, format: Date::DATE_FORMATS[:medium]),
        end_date: l(timebox.due_date, format: Date::DATE_FORMATS[:medium])
      }
    elsif timebox.due_date
      if timebox.due_date.past?
        _("expired on %{timebox_due_date}") % {
          timebox_due_date: l(timebox.due_date,
            format: Date::DATE_FORMATS[:medium])
        }
      else
        _("expires on %{timebox_due_date}") % {
          timebox_due_date: l(timebox.due_date,
            format: Date::DATE_FORMATS[:medium])
        }
      end
    elsif timebox.start_date
      if timebox.start_date.past?
        _("started on %{timebox_start_date}") % {
          timebox_start_date: l(timebox.start_date,
            format: Date::DATE_FORMATS[:medium])
        }
      else
        _("starts on %{timebox_start_date}") % {
          timebox_start_date: l(timebox.start_date,
            format: Date::DATE_FORMATS[:medium])
        }
      end
    end
  end
  alias_method :milestone_date_range, :timebox_date_range

  def milestone_tab_path(milestone, tab, params = {})
    url_for(params.merge(action: tab, format: :json))
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

    group_milestone_path(milestone.group, milestone.iid, milestone: params)
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

  def display_issues_count_warning?(milestone)
    milestone_visible_issues_count(milestone) > Milestone::DISPLAY_ISSUES_LIMIT
  end

  def milestone_issues_count_message(milestone)
    total_count = milestone_visible_issues_count(milestone)
    limit = Milestone::DISPLAY_ISSUES_LIMIT
    link_options = { milestone_title: @milestone.title }

    message = _('Showing %{limit} of %{total_count} issues. ') % { limit: limit, total_count: total_count }
    message += link_to(_('View all issues'), milestones_issues_path(link_options))

    message.html_safe
  end

  private

  def milestone_visible_issues_count(milestone)
    @milestone_visible_issues_count ||= milestone.issues_visible_to_user(current_user).size
  end
end

TimeboxesHelper.prepend_mod_with('TimeboxesHelper')
