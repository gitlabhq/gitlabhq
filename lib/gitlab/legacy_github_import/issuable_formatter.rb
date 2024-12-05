# frozen_string_literal: true

module Gitlab
  module LegacyGithubImport
    class IssuableFormatter < BaseFormatter
      include Import::UsernameMentionRewriter

      attr_writer :assignee_id, :author_id

      def project_association
        raise NotImplementedError
      end

      def number
        raw_data[:number]
      end

      def find_condition
        { iid: number }
      end

      def create!
        record = super

        return record unless assignee_id

        # Fetch first assignee because Gitea's API only returns one assignee for issue assignees
        assignee_record = record.method(project_assignee_association).call.first
        push_placeholder_references(assignee_record, contributing_users: contributing_assignee_formatters)

        record
      end

      def project_assignee_association
        raise NotImplementedError
      end

      def contributing_assignee_formatters
        raise NotImplementedError
      end

      private

      def state
        raw_data[:state] == 'closed' ? 'closed' : 'opened'
      end

      def assigned?
        raw_data[:assignee].present?
      end

      def author
        @author ||= UserFormatter.new(client, raw_data[:user], project, source_user_mapper)
      end

      def author_id
        @author_id ||= author.gitlab_id || project.creator_id
      end

      def assignee
        if assigned?
          @assignee ||= UserFormatter.new(client, raw_data[:assignee], project, source_user_mapper)
        end
      end

      def assignee_id
        return @assignee_id if defined?(@assignee_id)

        @assignee_id = assignee.try(:gitlab_id)
      end

      def body
        wrap_mentions_in_backticks(raw_data[:body]) || ""
      end

      def description
        if author.gitlab_id
          body
        else
          formatter.author_line(author.login) + body
        end
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def milestone
        if raw_data[:milestone].present?
          milestone = MilestoneFormatter.new(project, raw_data[:milestone])
          project.milestones.find_by(milestone.find_condition)
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
