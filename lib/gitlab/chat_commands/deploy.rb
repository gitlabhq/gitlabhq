module Gitlab
  module ChatCommands
    class Deploy < BaseCommand
      def self.match(text)
        /\Adeploy\s+(?<from>.*)\s+to+\s+(?<to>.*)\z/.match(text)
      end

      def self.help_message
        'deploy <environment> to <target-environment>'
      end

      def self.allowed?(project, user)
        can?(user, :create_deployment, project)
      end

      def execute(match)
        from = match[:from]
        to = match[:to]

        environment = project.environments.find_by(name: from)
        return unless environment

        actions = environment.actions_for(to)
        return unless actions.any?

        if actions.one?
          actions.first.play(current_user)
        else
          Result.new(:error, 'Too many actions defined')
        end
      end
    end
  end
end
