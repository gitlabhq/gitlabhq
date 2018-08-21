module Gitlab
  module HookData
    class IssueBuilder < BaseBuilder
<<<<<<< HEAD
      prepend ::EE::Gitlab::HookData::IssueBuilder

=======
>>>>>>> upstream/master
      SAFE_HOOK_RELATIONS = %i[
        assignees
        labels
        total_time_spent
      ].freeze

      def self.safe_hook_attributes
        %i[
          assignee_id
          author_id
          closed_at
          confidential
          created_at
          description
          due_date
          id
          iid
          last_edited_at
          last_edited_by_id
          milestone_id
          moved_to_id
          project_id
          relative_position
          state
          time_estimate
          title
          updated_at
          updated_by_id
        ].freeze
      end

      alias_method :issue, :object

      def build
        attrs = {
            description: absolute_image_urls(issue.description),
            url: Gitlab::UrlBuilder.build(issue),
            total_time_spent: issue.total_time_spent,
            human_total_time_spent: issue.human_total_time_spent,
            human_time_estimate: issue.human_time_estimate,
            assignee_ids: issue.assignee_ids,
            assignee_id: issue.assignee_ids.first # This key is deprecated
        }

        issue.attributes.with_indifferent_access.slice(*self.class.safe_hook_attributes)
<<<<<<< HEAD
          .merge!(attrs)
=======
            .merge!(attrs)
>>>>>>> upstream/master
      end
    end
  end
end
