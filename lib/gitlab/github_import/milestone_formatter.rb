module Gitlab
  module GithubImport
    class MilestoneFormatter < BaseFormatter
      def attributes
        {
          iid: number,
          project: project,
          title: title,
          description: description,
          due_date: due_date,
          state: state,
          created_at: created_at,
          updated_at: updated_at
        }
      end

      private

      def number
        raw_data.number
      end

      def title
        raw_data.title
      end

      def description
        raw_data.description
      end

      def due_date
        raw_data.due_on
      end

      def state
        raw_data.state == 'closed' ? 'closed' : 'active'
      end

      def created_at
        raw_data.created_at
      end

      def updated_at
        state == 'closed' ? raw_data.closed_at : raw_data.updated_at
      end
    end
  end
end
