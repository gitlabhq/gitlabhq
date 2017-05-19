class IssueEntity < IssuableEntity
  include RequestAwareEntity

  expose :branch_name
  expose :confidential
  expose :assignees, using: API::Entities::UserBasic
  expose :due_date
  expose :moved_to_id
  expose :project_id
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity

  expose :path do |issue|
    namespace_project_issue_path(issue.project.namespace, issue.project, issue)
  end
end
