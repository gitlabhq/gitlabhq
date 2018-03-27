module Gitlab
  module LegacyGithubImport
    class IssuableFormatter < BaseFormatter
      attr_writer :assignee_id, :author_id

      def project_association
        raise NotImplementedError
      end

      delegate :number, to: :raw_data

      def find_condition
        { iid: number }
      end

      private

      def state
        raw_data.state == 'closed' ? 'closed' : 'opened'
      end

      def assigned?
        raw_data.assignee.present?
      end

      def author
        @author ||= UserFormatter.new(client, raw_data.user)
      end

      def author_id
        @author_id ||= author.gitlab_id || project.creator_id
      end

      def assignee
        if assigned?
          @assignee ||= UserFormatter.new(client, raw_data.assignee)
        end
      end

      def assignee_id
        return @assignee_id if defined?(@assignee_id)

        @assignee_id = assignee.try(:gitlab_id)
      end

      def body
        raw_data.body || ""
      end

      def description
        if author.gitlab_id
          body
        else
          formatter.author_line(author.login) + body
        end
      end

      def milestone
        if raw_data.milestone.present?
          milestone = MilestoneFormatter.new(project, raw_data.milestone)
          project.milestones.find_by(milestone.find_condition)
        end
      end
    end
  end
end
