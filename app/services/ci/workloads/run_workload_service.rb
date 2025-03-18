# frozen_string_literal: true

module Ci
  module Workloads
    # The concept of `Workload` is an abstraction around running arbitrary compute on our `CI::Runners` infrastructure.
    # Right now this class is simply a wrapper around constructing a `Ci::Pipeline` but we've identified a need in many
    # parts of the GitLab application to create these workloads. Also see:
    #   1. https://gitlab.com/gitlab-org/gitlab/-/issues/328489
    #   2. https://gitlab.com/gitlab-com/content-sites/handbook/-/merge_requests/10811
    #
    # In the future it's likely that this class will persist additional models and the concept of a `Workload` may
    # become first class. For that reason we abstract users from the underlying `Ci::Pipeline` semantics.
    class RunWorkloadService
      def initialize(project:, current_user:, source:, workload:, create_branch: false)
        @project = project
        @current_user = current_user
        @source = source
        @workload = workload
        @create_branch = create_branch
      end

      def execute
        validate_source!
        ref = @create_branch ? create_repository_branch : default_branch

        service = ::Ci::CreatePipelineService.new(@project, @current_user, ref: ref)
        service.execute(
          @source,
          ignore_skip_ci: true,
          save_on_errors: false,
          content: content
        )
      end

      private

      def create_repository_branch
        branch_name = "workloads/#{SecureRandom.hex[0..10]}"
        raise "Branch already exists" if @project.repository.branch_exists?(branch_name)

        repo_branch = @project.repository.add_branch(@current_user, branch_name, default_branch, skip_ci: true)
        raise "Error in git branch creation" unless repo_branch

        branch_name
      end

      def content
        { workload: @workload.job }.deep_stringify_keys.to_yaml
      end

      def default_branch
        @project.default_branch_or_main
      end

      def validate_source!
        return if ::Enums::Ci::Pipeline.workload_sources.include?(@source)

        raise ArgumentError, "unsupported source `#{@source}` for workloads"
      end
    end
  end
end
