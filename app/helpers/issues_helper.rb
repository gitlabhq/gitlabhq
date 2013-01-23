module IssuesHelper
  def project_issues_filter_path project, params = {}
    params[:f] ||= cookies['issue_filter']
    project_issues_path project, params
  end

  def issue_css_classes issue
    classes = "issue"
    classes << " closed" if issue.closed?
    classes << " today" if issue.today?
    classes
  end

  def issue_tags
    @project.issues.tag_counts_on(:labels).map(&:name)
  end

  # Returns an OpenStruct object suitable for use by <tt>options_from_collection_for_select</tt>
  # to allow filtering issues by an unassigned User or Milestone
  def unassigned_filter
    # Milestone uses :title, Issue uses :name
    OpenStruct.new(id: 0, title: 'Unspecified', name: 'Unassigned')
  end

  def issues_filter
    {
      all: "all",
      closed: "closed",
      to_me: "assigned-to-me",
      open: "open"
    }
  end

  def labels_autocomplete_source
    labels = @project.issues_labels.order('count DESC')
    labels = labels.map{ |l| { label: l.name, value: l.name } }
    labels.to_json
  end

  def issues_active_milestones
    @project.milestones.active.order("id desc").all
  end

  def url_for_issue(issue_id)
    if @project.issues_tracker ==  Project.issues_tracker.default_value
      url = project_issue_url project_id: @project, id: issue_id
    else
      url = Settings[:issues_tracker][@project.issues_tracker]["issues_url"]
      url.gsub(':id', issue_id.to_s).gsub(':project_id', @project.id.to_s)
    end
  end

  def title_for_issue(issue_id)
    if issue = @project.issues.where(id: issue_id).first
      issue.title
    else
      ""
    end
  end

  def issue_exists?(issue_id)
    return false if @project.nil?

    if @project.issues_tracker == Project.issues_tracker.default_value
      @project.issues.where(id: issue_id).first.present?
    else
      true
    end
  end
end
