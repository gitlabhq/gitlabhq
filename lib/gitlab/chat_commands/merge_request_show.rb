module Gitlab
  module ChatCommands
    class MergeRequestShow < MergeRequestCommand
      def self.match(text)
        /\Amergerequest\s+show\s+(?<iid>\d+)/.match(text)
      end

      def self.help_message
        "mergerequest show <id>"
      end

      def execute(match)
        present find_by_iid(match[:iid])
      end
    end
  end
end
