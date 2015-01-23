class IssueTrackerService < Service

  def category
    :issue_tracker
  end

  def project_url
    # implement inside child
  end

  def issues_url
    # implement inside child
  end

  def new_issue_url
    # implement inside child
  end
end
