module Ci
  class StopEnvironmentService < BaseService
    attr_reader :ref

    def execute(branch_name)
      @ref = branch_name

      return unless has_ref_commit_pair?
      return unless has_environments?

      environments.each do |environment|
        next unless environment.stoppable?

        environment.stop!(current_user)
      end
    end

    private

    def has_ref_commit_pair?
      ref && commit
    end

    def commit
      @commit ||= project.commit(ref)
    end

    def has_environments?
      environments.any?
    end

    def environments
      @environments ||= project.environments_for(ref, commit)
    end
  end
end
