module Ci
  class StopEnvironmentsService < BaseService
    attr_reader :ref

    def execute(branch_name)
      @ref = branch_name

      return unless has_ref?

      environments.each do |environment|
        next unless can?(current_user, :create_deployment, project)

        environment.stop_with_action!(current_user)
      end
    end

    private

    def has_ref?
      @ref.present?
    end

    def environments
      @environments ||=
        EnvironmentsFinder.new(project, current_user, ref: @ref, recently_updated: true).execute
    end
  end
end
