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
      def initialize(
        project:, current_user:, source:, workload_definition:, ref: nil,
        ci_variables_included: [])
        @project = project
        @current_user = current_user
        @source = source
        @workload_definition = workload_definition
        @ref = ref || @project.default_branch_or_main
        @ci_variables_included = ci_variables_included
      end

      def execute
        validate_source!

        @workload_definition.add_variable(:CI_WORKLOAD_REF, @ref)
        service = ::Ci::CreatePipelineService.new(@project, @current_user, ref: @ref)
        response = service.execute(
          @source,
          ignore_skip_ci: true,
          save_on_errors: false,
          content: ci_job_yaml
        )

        pipeline = response.payload

        unless pipeline.created_successfully?
          return ServiceResponse.error(message: "Error in creating workload: #{pipeline.full_error_messages}")
        end

        workload = ::Ci::Workloads::Workload.create!(
          project_id: @project.id,
          pipeline: pipeline,
          branch_name: @ref
        )

        create_included_ci_variables(workload)

        ServiceResponse.success(payload: workload)
      end

      private

      # By default a Workload will not get any of the CI variables configured at the project/group/instance level.
      # Setting ci_included_variables option ensures these named variables will later be made available from the CI
      # variables configured at the project/group/instance level.
      def create_included_ci_variables(workload)
        @ci_variables_included.each do |var|
          workload.variable_inclusions.create!(variable_name: var, project: workload.project)
        end
      end

      def ci_job_yaml
        { workload: @workload_definition.to_job_hash }.deep_stringify_keys.to_yaml
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
