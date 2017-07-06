class IssueEntity < IssuableEntity
  include RequestAwareEntity

  expose :branch_name
  expose :confidential
  expose :assignees, using: API::Entities::UserBasic
  expose :due_date
  expose :moved_to_id
  expose :project_id
  expose :weight, if: ->(issue, _) { issue.supports_weight? }
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity

  expose :web_url do |issue|
    project_issue_path(issue.project, issue)
  end
end
