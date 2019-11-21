# frozen_string_literal: true

module IssuesHelper
  def issue_css_classes(issue)
    classes = ["issue"]
    classes << "closed" if issue.closed?
    classes << "today" if issue.today?
    classes << "user-can-drag" if @sort == 'relative_position'
    classes.join(' ')
  end

  # Returns an OpenStruct object suitable for use by <tt>options_from_collection_for_select</tt>
  # to allow filtering issues by an unassigned User or Milestone
  def unassigned_filter
    # Milestone uses :title, Issue uses :name
    OpenStruct.new(id: 0, title: 'None (backlog)', name: 'Unassigned')
  end

  def url_for_issue(issue_iid, project = @project, options = {})
    return '' if project.nil?

    url =
      if options[:internal]
        url_for_internal_issue(issue_iid, project, options)
      else
        url_for_tracker_issue(issue_iid, project, options)
      end

    # Ensure we return a valid URL to prevent possible XSS.
    URI.parse(url).to_s
  rescue URI::InvalidURIError
    ''
  end

  def url_for_tracker_issue(issue_iid, project, options)
    if options[:only_path]
      project.issues_tracker.issue_path(issue_iid)
    else
      project.issues_tracker.issue_url(issue_iid)
    end
  end

  def url_for_internal_issue(issue_iid, project = @project, options = {})
    helpers = Gitlab::Routing.url_helpers

    if options[:only_path]
      helpers.namespace_project_issue_path(namespace_id: project.namespace, project_id: project, id: issue_iid)
    else
      helpers.namespace_project_issue_url(namespace_id: project.namespace, project_id: project, id: issue_iid)
    end
  end

  def status_box_class(item)
    if item.try(:expired?)
      'status-box-expired'
    elsif item.try(:merged?)
      'status-box-mr-merged'
    elsif item.closed?
      'status-box-mr-closed'
    elsif item.try(:upcoming?)
      'status-box-upcoming'
    else
      'status-box-open'
    end
  end

  def issue_status_visibility(issue, status_box:)
    case status_box
    when :open
      'hidden' if issue.closed?
    when :closed
      'hidden' unless issue.closed?
    end
  end

  def issue_button_visibility(issue, closed)
    return 'hidden' if issue_button_hidden?(issue, closed)
  end

  def issue_button_hidden?(issue, closed)
    issue.closed? == closed || (!closed && issue.discussion_locked)
  end

  def confidential_icon(issue)
    icon('eye-slash') if issue.confidential?
  end

  def award_user_list(awards, current_user, limit: 10)
    names = awards.map do |award|
      award.user == current_user ? 'You' : award.user.name
    end

    current_user_name = names.delete('You')
    names = names.insert(0, current_user_name).compact.first(limit)

    names << "#{awards.size - names.size} more." if awards.size > names.size

    names.to_sentence
  end

  def award_state_class(awardable, awards, current_user)
    if !can?(current_user, :award_emoji, awardable)
      "disabled"
    elsif current_user && awards.find { |a| a.user_id == current_user.id }
      "active"
    else
      ""
    end
  end

  def awards_sort(awards)
    awards.sort_by do |award, award_emojis|
      if award == "thumbsup"
        0
      elsif award == "thumbsdown"
        1
      else
        2
      end
    end.to_h
  end

  def link_to_discussions_to_resolve(merge_request, single_discussion = nil)
    link_text = [merge_request.to_reference]
    link_text << "(discussion #{single_discussion.first_note.id})" if single_discussion

    path = if single_discussion
             Gitlab::UrlBuilder.build(single_discussion.first_note)
           else
             project = merge_request.project
             project_merge_request_path(project, merge_request)
           end

    link_to link_text.join(' '), path
  end

  def show_new_issue_link?(project)
    return false unless project
    return false if project.archived?

    # We want to show the link to users that are not signed in, that way they
    # get directed to the sign-in/sign-up flow and afterwards to the new issue page.
    return true unless current_user

    can?(current_user, :create_issue, project)
  end

  def create_confidential_merge_request_enabled?
    Feature.enabled?(:create_confidential_merge_request, @project, default_enabled: true)
  end

  def show_new_branch_button?
    can_create_confidential_merge_request? || !@issue.confidential?
  end

  def can_create_confidential_merge_request?
    @issue.confidential? && !@project.private? &&
      create_confidential_merge_request_enabled? &&
      can?(current_user, :create_merge_request_in, @project)
  end

  def issue_closed_link(issue, current_user, css_class: '')
    if issue.moved? && can?(current_user, :read_issue, issue.moved_to)
      link_to(s_('IssuableStatus|moved'), issue.moved_to, class: css_class)
    elsif issue.duplicated? && can?(current_user, :read_issue, issue.duplicated_to)
      link_to(s_('IssuableStatus|duplicated'), issue.duplicated_to, class: css_class)
    end
  end

  def issue_closed_text(issue, current_user)
    link = issue_closed_link(issue, current_user, css_class: 'text-white text-underline')

    if link
      s_('IssuableStatus|Closed (%{link})').html_safe % { link: link }
    else
      s_('IssuableStatus|Closed')
    end
  end

  # Required for Banzai::Filter::IssueReferenceFilter
  module_function :url_for_issue
  module_function :url_for_internal_issue
  module_function :url_for_tracker_issue
end

IssuesHelper.prepend_if_ee('EE::IssuesHelper')
