# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class Deploy < BaseCommand
      DEPLOY_REGEX = /\Adeploy\s/

      def self.match(text)
        return unless text&.match?(DEPLOY_REGEX)

        from, _, to = text.sub(DEPLOY_REGEX, '').rpartition(/\sto+\s/)
        return if from.blank? || to.blank?

        {
          from: from.strip,
          to: to.strip
        }
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

      # rubocop: disable CodeReuse/ActiveRecord
      def find_action(from, to)
        environment = project.environments.find_by(name: from)
        return unless environment

        actions = environment.actions_for(to).select do |action|
          action.deployment_job?
        end

        if actions.many?
          actions.find { |action| action.name == to.to_s }
        else
          actions.first
        end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
