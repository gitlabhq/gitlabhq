# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Tasks
        class AgentPlanContent < Task
          def self.id = 'agent_plan_content'

          def human_name = 'Agent Plan Content'

          def destination_path = 'agent_plan_content.tar.gz'

          private

          def local
            Gitlab::Backup::Cli::Targets::Files.new(context, storage_path, excludes: ['tmp'])
          end

          def storage_path = context.agent_plan_content_path
        end
      end
    end
  end
end
