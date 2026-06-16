# frozen_string_literal: true

module Backup
  module Tasks
    class AgentPlanContent < Task
      def self.id = 'agent_plan_content'

      def human_name
        _('agent plan content')
      end

      def destination_path
        'agent_plan_content.tar.gz'
      end

      private

      def target
        @target ||= ::Backup::Targets::Files.new(progress, storage_path, options: options, excludes: ['tmp'])
      end

      def storage_path
        Settings.agent_plan_content.storage_path
      end
    end
  end
end
