# frozen_string_literal: true

module IssuesHelper
  def issue_css_classes(issue)
    classes = ["issue"]
    classes << "closed" if issue.closed?
    classes << "today" if issue.new?
    classes << "user-can-drag" if @sort == 'relative_position'
    classes.join(' ')
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
    sprite_icon('eye-slash', css_class: 'gl-vertical-align-text-bottom') if issue.confidential?
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

  def show_new_branch_button?
    can_create_confidential_merge_request? || !@issue.confidential?
  end

  def can_create_confidential_merge_request?
    @issue.confidential? && !@project.private? &&
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

  def show_moved_service_desk_issue_warning?(issue)
    return false unless issue.moved_from
    return false unless issue.from_service_desk?

    issue.moved_from.project.service_desk_enabled? && !issue.project.service_desk_enabled?
  end

  def use_startup_call?
    request.query_parameters.empty? && @sort == 'created_date'
  end

  def startup_call_params
    {
      state: 'opened',
      with_labels_details: 'true',
      page: 1,
      per_page: 20,
      order_by: 'created_at',
      sort: 'desc'
    }
  end

  def issue_header_actions_data(project, issuable, current_user)
    new_issuable_params = ({ issuable_template: 'incident', issue: { issue_type: 'incident' } } if issuable.incident?)

    {
      can_create_issue: show_new_issue_link?(project).to_s,
      can_reopen_issue: can?(current_user, :reopen_issue, issuable).to_s,
      can_report_spam: issuable.submittable_as_spam_by?(current_user).to_s,
      can_update_issue: can?(current_user, :update_issue, issuable).to_s,
      iid: issuable.iid,
      is_issue_author: (issuable.author == current_user).to_s,
      issue_type: issuable_display_type(issuable),
      new_issue_path: new_project_issue_path(project, new_issuable_params),
      project_path: project.full_path,
      report_abuse_path: new_abuse_report_path(user_id: issuable.author.id, ref_url: issue_url(issuable)),
      submit_as_spam_path: mark_as_spam_project_issue_path(project, issuable)
    }
  end

  # Overridden in EE
  def scoped_labels_available?(parent)
    false
  end
end

IssuesHelper.prepend_if_ee('EE::IssuesHelper')
