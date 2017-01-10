module Gitlab
  module ChatCommands
    class IssueSearch < IssueCommand
      def self.match(text)
        /\Aissue\s+search\s+(?<query>.*)/.match(text)
      end

      def self.help_message
        "issue search <your query>"
      end

      def execute(match)
        issues = collection.search(match[:query]).limit(QUERY_LIMIT)

        if issues.none?
          Presenters::Access.new(issues).not_found
        elsif issues.one?
          Presenters::ShowIssue.new(issues.first).present
        else
          Presenters::ListIssues.new(issues).present
        end
      end
    end
  end
end
