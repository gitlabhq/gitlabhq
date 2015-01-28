class GitlabIssueTrackerService < IssueTrackerService

  prop_accessor :title, :description, :project_url, :issues_url, :new_issue_url


  def default?
    true
  end

  def to_param
    'gitlab'
  end
end
