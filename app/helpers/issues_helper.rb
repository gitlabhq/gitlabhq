module IssuesHelper
  def issue_css_classes issue
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

  def url_for_project_issues
    return "" if @project.nil?

    if @project.used_default_issues_tracker? || !external_issues_tracker_enabled?
      project_issues_path(@project)
    else
      url = Gitlab.config.issues_tracker[@project.issues_tracker]["project_url"]
      url.gsub(':project_id', @project.id.to_s)
         .gsub(':issues_tracker_id', @project.issues_tracker_id.to_s)
    end
  end

  def url_for_new_issue
    return "" if @project.nil?

    if @project.used_default_issues_tracker? || !external_issues_tracker_enabled?
      url = new_project_issue_path project_id: @project
    else
      url = Gitlab.config.issues_tracker[@project.issues_tracker]["new_issue_url"]
      url.gsub(':project_id', @project.id.to_s)
        .gsub(':issues_tracker_id', @project.issues_tracker_id.to_s)
    end
  end

  def url_for_issue(issue_iid)
    return "" if @project.nil?

    if @project.used_default_issues_tracker? || !external_issues_tracker_enabled?
      url = project_issue_url project_id: @project, id: issue_iid
    else
      url = Gitlab.config.issues_tracker[@project.issues_tracker]["issues_url"]
      url.gsub(':id', issue_iid.to_s)
        .gsub(':project_id', @project.id.to_s)
        .gsub(':issues_tracker_id', @project.issues_tracker_id.to_s)
    end
  end

  def title_for_issue(issue_iid)
    return "" if @project.nil?

    if @project.used_default_issues_tracker? && issue = @project.issues.where(iid: issue_iid).first
      issue.title
    else
      ""
    end
  end

  # Checks if issues_tracker setting exists in gitlab.yml
  def external_issues_tracker_enabled?
    if Gitlab.config.issues_tracker && Gitlab.config.issues_tracker.values.any?
      true
    else
      false
    end
  end

  def bulk_update_milestone_options
    options_for_select(["None (backlog)"]) + options_from_collection_for_select(project_active_milestones, "id", "title", params[:milestone_id])
  end

  def bulk_update_assignee_options
    options_for_select(["None (unassigned)"]) + options_from_collection_for_select(@project.team.members, "id", "name", params[:assignee_id])
  end

  def assignee_options object
    options_from_collection_for_select(@project.team.members.sort_by(&:name), 'id', 'name', object.assignee_id)
  end

  def milestone_options object
    options_from_collection_for_select(@project.milestones.active, 'id', 'title', object.milestone_id)
  end

  def issue_alert_class(issue)
    if issue.closed?
      'alert-danger'
    else
      'alert-success'
    end
  end
end
