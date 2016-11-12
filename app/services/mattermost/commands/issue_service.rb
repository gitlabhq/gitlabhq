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

      #TODO implement create
      def subcommands
        %w[creates search show]
      end

      def collection
        project.issues
      end

      def readable?(issue)
        can?(current_user, :read_issue, issue)
      end

      # 'issue create my new title\nmy new description
      # => 'create', ['my', 'new', 'title, ['my new description']]
      # 'issue show 123'
      # => 'show', ['123']
      def parse_command
        split = command.split
        subcommand = split[1]
        args = split[2..-1]

        return subcommand, args
      end
    end
  end
end
