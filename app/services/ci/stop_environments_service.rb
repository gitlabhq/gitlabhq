module Ci
  class StopEnvironmentsService < BaseService
    attr_reader :ref

    def execute(branch_name)
      @ref = branch_name

      return unless has_ref?
      return unless can?(current_user, :create_deployment, project)

      environments.each do |environment|
        next unless environment.can_trigger_stop_action?(current_user)

        environment.stop_with_action!(current_user)
      end
    end

    private

    def has_ref?
      @ref.present?
    end

    def environments
      @environments ||= EnvironmentsFinder
        .new(project, current_user, ref: @ref, recently_updated: true)
        .execute
    end
  end
end
