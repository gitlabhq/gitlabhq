# frozen_string_literal: true

module API
  module Entities
    class IssueBasic < IssuableEntity
      format_with(:upcase) do |item|
        item.upcase if item.respond_to?(:upcase)
      end

      expose :closed_at
      expose :closed_by, using: Entities::UserBasic

      expose :labels do |issue, options|
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
             documentation: { type: "String", desc: "One of #{::Issue.issue_types.keys.map(&:upcase)}" }

      expose :assignee, using: ::API::Entities::UserBasic do |issue|
        issue.assignees.first
      end

      expose(:user_notes_count)     { |issue, options| issuable_metadata.user_notes_count }
      expose(:merge_requests_count) { |issue, options| issuable_metadata.merge_requests_count }
      expose(:upvotes)              { |issue, options| issuable_metadata.upvotes }
      expose(:downvotes)            { |issue, options| issuable_metadata.downvotes }
      expose :due_date
      expose :confidential
      expose :discussion_locked
      expose :issue_type

      expose :web_url do |issue|
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
