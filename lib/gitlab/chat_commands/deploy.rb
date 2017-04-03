module Gitlab
  module ChatCommands
    class Deploy < BaseCommand
      def self.match(text)
        /\Adeploy\s+(?<from>\S+.*)\s+to+\s+(?<to>\S+.*)\z/.match(text)
      end

      def self.help_message
        'deploy <environment> to <target-environment>'
      end

      def self.available?(project)
        project.builds_enabled?
      end

      def self.allowed?(project, user)
        can?(user, :create_deployment, project)
      end

      def execute(match)
        from = match[:from]
        to = match[:to]

        actions = find_actions(from, to)

        if actions.none?
          Gitlab::ChatCommands::Presenters::Deploy.new(nil).no_actions
        elsif actions.one?
          action = play!(from, to, actions.first)
          Gitlab::ChatCommands::Presenters::Deploy.new(action).present(from, to)
        else
          Gitlab::ChatCommands::Presenters::Deploy.new(actions).too_many_actions
        end
      end

      private

      def play!(from, to, action)
        action.play(current_user)
      end

      def find_actions(from, to)
        environment = project.environments.find_by(name: from)
        return [] unless environment

        environment.actions_for(to).select(&:starts_environment?)
      end
    end
  end
end
