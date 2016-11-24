module Ci
  class StopEnvironmentsService < BaseService
    attr_reader :ref

    def execute(branch_name)
      @ref = branch_name

      return unless has_ref?

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

    def environments
      @environments ||= project
        .environments_recently_updated_on_branch(@ref)
    end
  end
end
