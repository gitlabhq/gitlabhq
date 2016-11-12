module Mattermost
  module Commands
    class MergeRequestService < Mattermost::Commands::BaseService
      class << self
        def triggered_by?(command)
          command == 'mergerequest'
        end

        def available?(project)
          project.merge_requests_enabled?
        end

        def help_message(project)
          return nil unless available?(project)

          message = "mergerequest show <merge request id>\n"
          message << "mergerequest search <query>"
        end
      end

      private

      def subcommands
        %w[show search]
      end

      def collection
        project.merge_requests
      end

      def readable?(_)
        can?(current_user, :read_merge_request, project)
      end

      # 'mergerequest show 123' => 'show', ['123']
      # 'mergerequest search my query' => 'search',['my', 'query']
      def parse_command
        split = command.split
        subcommand = split[1]
        args = split[2..-1]

        [subcommand, args]
      end
    end
  end
end
