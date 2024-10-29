# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class IssueSearch < IssueCommand
      def self.match(text)
        /\Aissue\s+search\s+(?<query>.*)/.match(text)
      end

      def self.help_message
        "issue search <your query>"
      end

      def execute(match)
        issues = collection.search(match[:query]).limit(QUERY_LIMIT)

        if issues.present?
          Presenters::IssueSearch.new(issues).present
        else
          Presenters::Access.new(issues).not_found
        end
      end
    end
  end
end
