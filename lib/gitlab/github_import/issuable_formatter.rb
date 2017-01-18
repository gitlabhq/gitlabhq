module Gitlab
  module GithubImport
    class IssuableFormatter < BaseFormatter
      def project_association
        raise NotImplementedError
      end

      def number
        raw_data.number
      end

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

      def assignee_id
        if assigned?
          gitlab_user_id(raw_data.assignee.id)
        end
      end

      def author
        raw_data.user.login
      end

      def author_id
        gitlab_author_id || project.creator_id
      end

      def body
        raw_data.body || ""
      end

      def description
        if gitlab_author_id
          body
        else
          formatter.author_line(author) + body
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
