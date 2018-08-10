module EE
  module EnvironmentEntity
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    prepended do
      expose :logs_path, if: -> (*) { can_read_pod_logs? } do |environment|
        logs_project_environment_path(environment.project, environment)
      end
    end

    private

    def can_read_pod_logs?
      can?(current_user, :read_pod_logs, environment.project)
    end
  end
end
