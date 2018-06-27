class IssueEntity < IssuableEntity
  include TimeTrackableEntity

  expose :state
  expose :milestone_id
  expose :updated_by_id
  expose :created_at
  expose :updated_at
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity
  expose :lock_version
  expose :author_id
  expose :confidential
  expose :discussion_locked
  expose :assignees, using: API::Entities::UserBasic
  expose :due_date
  expose :moved_to_id
  expose :project_id

  expose :web_url do |issue|
    project_issue_path(issue.project, issue)
  end

  expose :current_user do
    expose :can_create_note do |issue|
      can?(request.current_user, :create_note, issue)
    end

    expose :can_update do |issue|
      can?(request.current_user, :update_issue, issue)
    end

    expose :can_award_emoji do |issue|
      can?(request.current_user, :award_emoji, issue)
    end
  end

  expose :create_note_path do |issue|
    project_notes_path(issue.project, target_type: 'issue', target_id: issue.id)
  end

  expose :preview_note_path do |issue|
    preview_markdown_path(issue.project, quick_actions_target_type: 'Issue', quick_actions_target_id: issue.id)
  end
end
