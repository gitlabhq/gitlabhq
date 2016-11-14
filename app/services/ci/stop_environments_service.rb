module Ci
  class StopEnvironmentsService < BaseService
    attr_reader :ref

    def execute(branch_name)
      @ref = branch_name

      return unless has_ref?
      return unless has_environments?

      environments.each do |environment|
        next unless environment.stoppable?
        next unless can?(current_user, :create_deployment, project)

        environment.stop!(current_user)
      end
    end

    private

    def has_ref?
      @ref.present?
    end

    def has_environments?
      environments.any?
    end

    def environments
      @environments ||= project.environments_for(@ref)
    end
  end
end
