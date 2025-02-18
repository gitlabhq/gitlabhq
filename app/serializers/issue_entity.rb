# frozen_string_literal: true

class IssueEntity < IssuableEntity
  include TimeTrackableEntity

  format_with(:upcase) do |item|
    item.try(:upcase)
  end

  format_with(:iso8601) do |item|
    item.try(:iso8601)
  end

  expose :state
  expose :milestone_id
  expose :updated_by_id
  expose :created_at, format_with: :iso8601
  expose :updated_at, format_with: :iso8601
  expose :milestone, using: API::Entities::Milestone
  expose :labels, using: LabelEntity
  expose :lock_version
  expose :author_id
  expose :confidential
  expose :discussion_locked
  expose :assignees, using: API::Entities::UserBasic
  expose :due_date
  expose :project_id

  expose :moved_to_id do |issue|
    if issue.moved? && can?(request.current_user, :read_issue, issue.moved_to)
      issue.moved_to_id
    end
  end

  expose :duplicated_to_id do |issue|
    if issue.duplicated? && can?(request.current_user, :read_issue, issue.duplicated_to)
      issue.duplicated_to_id
    end
  end

  expose :web_url do |issue|
    Gitlab::UrlBuilder.build(issue, only_path: true)
  end

  expose :current_user do
    expose :can_create_note do |issue|
      can?(request.current_user, :create_note, issue)
    end

    expose :can_create_confidential_note do |issue|
      can?(request.current_user, :mark_note_as_internal, issue)
    end

    expose :can_update do |issue|
      can?(request.current_user, :update_issue, issue)
    end

    expose :can_set_issue_metadata do |issue|
      can?(request.current_user, :set_issue_metadata, issue)
    end

    expose :can_award_emoji do |issue|
      can?(request.current_user, :award_emoji, issue)
    end
  end

  expose :create_note_path do |issue|
    project_notes_path(issue.project, target_type: 'issue', target_id: issue.id)
  end

  expose :preview_note_path do |issue|
    preview_markdown_path(issue.project, target_type: 'Issue', target_id: issue.iid)
  end

  expose :confidential_issues_docs_path, if: ->(issue) { issue.confidential? } do |issue|
    help_page_path('user/project/issues/confidential_issues.md')
  end

  expose :locked_discussion_docs_path, if: ->(issue) { issue.discussion_locked? } do |issue|
    help_page_path('user/discussions/_index.md', anchor: 'prevent-comments-by-locking-the-discussion')
  end

  expose :is_project_archived do |issue|
    issue.project.archived?
  end

  expose :archived_project_docs_path, if: ->(issue) { issue.project.archived? } do |issue|
    help_page_path('user/project/working_with_projects.md', anchor: 'delete-a-project')
  end

  expose :issue_email_participants do |issue|
    presented_issue = issue.present(current_user: request.current_user)

    presented_issue.issue_email_participants.map do |participant|
      {
        email: participant.email
      }
    end
  end

  expose :issue_type,
    as: :type,
    format_with: :upcase,
    documentation: { type: "String", desc: "One of #{::WorkItems::Type.base_types.keys.map(&:upcase)}" }
end

IssueEntity.prepend_mod_with('IssueEntity')
