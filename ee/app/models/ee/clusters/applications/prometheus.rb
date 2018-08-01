module EE
  module Clusters
    module Applications
      module Prometheus
        extend ActiveSupport::Concern

        prepended do
          state_machine :status do
            after_transition any => :updating do |application|
              application.update(last_update_started_at: Time.now, version: application.class.const_get(:VERSION))
            end
          end
        end

        def ready_status
          super + [:updating, :updated, :update_errored]
        end

        def updated_since?(timestamp)
          last_update_started_at &&
            last_update_started_at > timestamp &&
            !update_errored?
        end

        def update_in_progress?
          status_name == :updating
        end

        def update_errored?
          status_name == :update_errored
        end

        def get_command
          ::Gitlab::Kubernetes::Helm::GetCommand.new(name)
        end

        # TODO allow users to chose which version to upgrade to.
        def upgrade_command(values)
          ::Gitlab::Kubernetes::Helm::UpgradeCommand.new(
            name,
            version: self.class.const_get(:VERSION),
            chart: chart,
            values: values
          )
        end
      end
    end
  end
end
