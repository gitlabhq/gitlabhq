# frozen_string_literal: true

module API
  module Entities
    class Issue < IssueBasic
      include ::API::Helpers::RelatedResourcesHelpers

      expose(:has_tasks, documentation: { type: 'Boolean', example: true }) do |issue, _|
        !issue.tasks?
      end

      expose :task_status, documentation: { type: 'String', example: '2 of 4 tasks completed' }, if: ->(issue, _) do
        !issue.tasks?
      end

      expose :_links, documentation: { type: 'Hash' } do
        expose :self,
          documentation: { type: 'String', example: 'http://example.com/api/v4/projects/1/issues/2' } do |issue|
          expose_url(api_v4_project_issue_path(id: issue.project_id, issue_iid: issue.iid))
        end

        expose :notes,
          documentation: { type: 'String', example: 'http://example.com/api/v4/projects/1/issues/2/notes' } do |issue|
          expose_url(api_v4_projects_issues_notes_path(id: issue.project_id, noteable_id: issue.iid))
        end

        expose :award_emoji,
          documentation: {
            type: 'String', example: 'http://example.com/api/v4/projects/1/issues/2/award_emoji'
          } do |issue|
          expose_url(api_v4_projects_issues_award_emoji_path(id: issue.project_id, issue_iid: issue.iid))
        end

        expose :project, documentation: { type: 'String', example: 'http://example.com/api/v4/projects/1' } do |issue|
          expose_url(api_v4_projects_path(id: issue.project_id))
        end

        expose :closed_as_duplicate_of,
          documentation: { type: 'String', example: 'http://example.com/api/v4/projects/1/issues/75' } do |issue|
          if issue.duplicated? && options[:current_user]&.can?(:read_issue, issue.duplicated_to)
            expose_url(
              api_v4_project_issue_path(id: issue.duplicated_to.project_id, issue_iid: issue.duplicated_to.iid)
            )
          end
        end
      end

      expose :references,
        with: IssuableReferences,
        documentation: { type: '::API::Entities::IssuableReferences' } do |issue|
        issue
      end

      expose :severity,
        format_with: :upcase,
        documentation: { type: "String", desc: "One of #{::IssuableSeverity.severities.keys.map(&:upcase)}" }

      # Calculating the value of subscribed field triggers Markdown
      # processing. We can't do that for multiple issues / merge
      # requests in a single API request.
      expose :subscribed,
        documentation: { type: 'Boolean', example: false },
        if: ->(_, options) { options.fetch(:include_subscribed, true) } do |issue, options|
        issue.subscribed?(options[:current_user], options[:project] || issue.project)
      end

      expose :moved_to_id, documentation: { type: 'Integer', example: 1 }
      expose :imported?, as: :imported, documentation: { type: 'Boolean', example: false }
      expose :imported_from, documentation: { type: 'String', example: 'github' }
      expose :service_desk_reply_to, documentation: { type: 'String', example: 'user@example.com' } do |issue|
        issue.present(
          current_user: options[:current_user],
          # We need to pass it explicitly to account for the case where `issue`
          # is a `WorkItem` which doesn't have a presenter yet.
          presenter_class: IssuePresenter
        ).service_desk_reply_to
      end
    end
  end
end

API::Entities::Issue.prepend_mod_with('API::Entities::Issue')
