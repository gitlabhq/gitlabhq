module IssuesHelper
  def issue_css_classes(issue)
    classes = "issue"
    classes << " closed" if issue.closed?
    classes << " today" if issue.today?
    classes
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

  def bulk_update_milestone_options
    milestones = @project.milestones.active.reorder(due_date: :asc, title: :asc).to_a
    milestones.unshift(Milestone::None)

    options_from_collection_for_select(milestones, 'id', 'title', params[:milestone_id])
  end

  def milestone_options(object)
    milestones = object.project.milestones.active.reorder(due_date: :asc, title: :asc).to_a
    milestones.unshift(object.milestone) if object.milestone.present? && object.milestone.closed?
    milestones.unshift(Milestone::None)

    options_from_collection_for_select(milestones, 'id', 'title', object.milestone_id)
  end

  def project_options(issuable, current_user, ability: :read_project)
    projects = current_user.authorized_projects
    projects = projects.select do |project|
      current_user.can?(ability, project)
    end

    no_project = OpenStruct.new(id: 0, name_with_namespace: 'No project')
    projects.unshift(no_project)
    projects.delete(issuable.project)

    options_from_collection_for_select(projects, :id, :name_with_namespace)
  end

  def status_box_class(item)
    if item.try(:expired?)
      'status-box-expired'
    elsif item.try(:merged?)
      'status-box-merged'
    elsif item.closed?
      'status-box-closed'
    elsif item.try(:upcoming?)
      'status-box-upcoming'
    else
      'status-box-open'
    end
  end

  def issue_button_visibility(issue, closed)
    return 'hidden' if issue.closed? == closed
  end

  def merge_requests_sentence(merge_requests)
    # Sorting based on the `!123` or `group/project!123` reference will sort
    # local merge requests first.
    merge_requests.map do |merge_request|
      merge_request.to_reference(@project)
    end.sort.to_sentence(last_word_connector: ', or ')
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

  def award_state_class(awards, current_user)
    if !current_user
      "disabled"
    elsif current_user && awards.find { |a| a.user_id == current_user.id }
      "active"
    else
      ""
    end
  end

  def award_user_authored_class(award)
    if award == 'thumbsdown' || award == 'thumbsup'
      'user-authored js-user-authored'
    else
      ''
    end
  end

  def awards_sort(awards)
    awards.sort_by do |award, notes|
      if award == "thumbsup"
        0
      elsif award == "thumbsdown"
        1
      else
        2
      end
    end.to_h
  end

  def due_date_options
    options = [
      Issue::AnyDueDate,
      Issue::NoDueDate,
      Issue::DueThisWeek,
      Issue::DueThisMonth,
      Issue::Overdue
    ]

    options_from_collection_for_select(options, 'name', 'title', params[:due_date])
  end

  def link_to_discussions_to_resolve(merge_request, single_discussion = nil)
    link_text = merge_request.to_reference
    link_text += " (discussion #{single_discussion.first_note.id})" if single_discussion

    path = if single_discussion
             Gitlab::UrlBuilder.build(single_discussion.first_note)
           else
             project = merge_request.project
             project_merge_request_path(project, merge_request)
           end

    link_to link_text, path
  end

  # Required for Banzai::Filter::IssueReferenceFilter
  module_function :url_for_issue
  module_function :url_for_internal_issue
  module_function :url_for_tracker_issue
end
