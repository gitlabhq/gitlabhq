# Finders::Issues class
#
# Used to filter Issues collections by set of params
#
# Arguments:
#   current_user - which user use
#   params:
#     scope: 'created-by-me' or 'assigned-to-me' or 'all'
#     state: 'open' or 'closed' or 'all'
#     group_id: integer
#     project_id: integer
#     milestone_id: integer
#     assignee_id: integer
#     search: string
#     label_name: string
#     sort: string
#
class IssuesFinder < IssuableFinder
  def klass
    Issue
  end

  private

  def init_collection
    IssuesFinder.not_restricted_by_confidentiality(current_user)
  end

  def self.not_restricted_by_confidentiality(user)
    return Issue.where('issues.confidential IS NULL OR issues.confidential IS FALSE') if user.blank?

    return Issue.all if user.admin_or_auditor?

    Issue.where('
      issues.confidential IS NULL
      OR issues.confidential IS FALSE
      OR (issues.confidential = TRUE
        AND (issues.author_id = :user_id
          OR issues.assignee_id = :user_id
          OR issues.project_id IN(:project_ids)))',
      user_id: user.id,
      project_ids: user.authorized_projects(Gitlab::Access::REPORTER).select(:id))
  end
end
