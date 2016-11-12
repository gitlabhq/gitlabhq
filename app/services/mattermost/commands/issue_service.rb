module Mattermost
  module Commands
    class IssueService < Mattermost::Commands::BaseService
      class << self
        def triggered_by?(command)
          command == 'issue'
        end

        def available?(project)
          project.issues_enabled? && project.default_issues_tracker?
        end

        def help_message(project)
          return nil unless available?(project)

          message = "issue show <issue_id>"
          message << "issue search <query>"
        end
      end

      private

      def create(_)
        return nil unless can?(current_user, :create_issue, project)

        # We parse again as the previous split splits on continues whitespace
        # per the ruby spec, but we loose information on where the new lines were
        match = command.match(/\Aissue create (?<title>.*)\n*/)
        title = match[:title]
        description = match.post_match

        Issues::CreateService.new(project, current_user, title: title, description: description).execute
      end

      def subcommands
        %w[create search show]
      end

      def collection
        project.issues
      end

      def readable?(issue)
        can?(current_user, :read_issue, issue)
      end

      def parse_command
        split = command.split
        subcommand = split[1]
        args = split[2..-1]

        [subcommand, args]
      end
    end
  end
end
