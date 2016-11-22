module Gitlab
  module ChatCommands
    class IssueCreate < IssueCommand
      def self.match(text)
        /\Aissue\s+create\s+(?<title>[^\n]*)\n*(?<description>.*)\z/.match(text)
      end

      def self.help_message
        'issue create <title>\n<description>'
      end

      def self.allowed?(project, user)
        can?(user, :create_issue, project)
      end

      def execute(match)
        title = match[:title]
        description = match[:description]

        Issues::CreateService.new(project, current_user, title: title, description: description).execute
      end
    end
  end
end
