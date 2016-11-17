module Gitlab
  module ChatCommands
    class MergeRequestSearch < MergeRequestCommand
      def self.match(text)
        /\Amergerequest\s+search\s+(?<query>.*)\s*/.match(text)
      end

      def self.help_message
        "mergerequest search <query>"
      end

      def execute(match)
        present search_results(match[:query])
      end
    end
  end
end
