# frozen_string_literal: true

module API
  module Entities
    class IssueBasic < IssuableEntity
      format_with(:upcase) do |item|
        item.upcase if item.respond_to?(:upcase)
      end

      expose :closed_at, documentation: { type: 'dateTime', example: '2022-11-15T08:30:55.232Z' }
      expose :closed_by, using: Entities::UserBasic

      expose :labels, documentation: { type: 'string', is_array: true, example: 'bug' } do |issue, options|
        if options[:with_labels_details]
          ::API::Entities::LabelBasic.represent(issue.labels.sort_by(&:title))
        else
          issue.labels.map(&:title).sort
        end
      end

      expose :milestone, using: Entities::Milestone
      expose :assignees, :author, using: Entities::UserBasic
      expose :issue_type,
        as: :type,
        format_with: :upcase,
        documentation: { type: 'String', example: 'ISSUE', desc: "One of #{::WorkItems::Type.allowed_types_for_issues.map(&:upcase)}" }

      expose :assignee, using: ::API::Entities::UserBasic do |issue|
        issue.assignees.first
      end

      expose(:user_notes_count)     { |issue, options| issuable_metadata.user_notes_count }
      expose(:merge_requests_count) { |issue, options| issuable_metadata.merge_requests_count }
      expose(:upvotes)              { |issue, options| issuable_metadata.upvotes }
      expose(:downvotes)            { |issue, options| issuable_metadata.downvotes }
      expose :due_date, documentation: { type: 'date', example: '2022-11-20' }
      expose :confidential, documentation: { type: 'boolean' }
      expose :discussion_locked, documentation: { type: 'boolean' }
      expose :issue_type, documentation: { type: 'string', example: 'issue' }

      expose :web_url, documentation: { type: 'string', example: 'http://example.com/example/example/issues/14' } do |issue|
        Gitlab::UrlBuilder.build(issue)
      end

      expose :time_stats, using: 'API::Entities::IssuableTimeStats' do |issue|
        issue
      end

      expose :task_completion_status
    end
  end
end

API::Entities::IssueBasic.prepend_mod_with('API::Entities::IssueBasic', with_descendants: true)
