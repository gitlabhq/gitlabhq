module Gitlab
  module SlashCommands
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

        action = find_action(from, to)

        if action.nil?
          Gitlab::SlashCommands::Presenters::Deploy
            .new(action).action_not_found
        else
          deployment = action.play(current_user)

          Gitlab::SlashCommands::Presenters::Deploy
            .new(deployment).present(from, to)
        end
      end

      private

      def find_action(from, to)
        environment = project.environments.find_by(name: from)
        return unless environment

        actions = environment.actions_for(to).select do |action|
          action.starts_environment?
        end

        if actions.many?
          actions.find { |action| action.name == to.to_s }
        else
          actions.first
        end
      end
    end
  end
end
