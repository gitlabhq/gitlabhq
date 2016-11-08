module Ci
  class StopEnvironmentService < BaseService
    def execute(ref)
      @ref = ref
      @commit = project.commit(ref)

      return unless has_ref_sha_pair?
      return unless has_environments?

      environments.each do |environment|
        next unless environment.stoppable?

        environment.stop!(current_user)
      end
    end

    private

    def has_ref_sha_pair?
      @ref && @commit
    end

    def has_environments?
      environments.any?
    end

    def environments
      @environments ||= project.environments_for(@ref, @commit)
    end
  end
end
