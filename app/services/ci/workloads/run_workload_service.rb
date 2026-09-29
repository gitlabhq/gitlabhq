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
      include Gitlab::Loggable

      # execve() caps one environment string at MAX_ARG_STRLEN, a kernel compile-time constant.
      # Past it, the job dies in prepare_script with "argument list too long" on every runner,
      # so reject here, where the caller learns which variable.
      MAX_VARIABLE_BYTESIZE = 128.kilobytes
      # The total is bounded by ARG_MAX, which scales with the runner's stack rlimit, so only log
      # it until we know how many workloads go over.
      WARN_VARIABLES_BYTESIZE = 1.megabyte

      def initialize(
        project:, current_user:, source:, workload_definition:, ref: nil,
        ci_variables_included: [], duo_workflow_definition: nil)
        @project = project
        @current_user = current_user
        @source = source
        @workload_definition = workload_definition
        @ref = ref || @project.default_branch_or_main
        @ci_variables_included = ci_variables_included
        @duo_workflow_definition = duo_workflow_definition
      end

      def execute
        validate_source!

        @workload_definition.add_variable(:CI_WORKLOAD_REF, @ref)

        oversized = validate_variables_size
        return oversized if oversized

        service = ::Ci::CreatePipelineService.new(@project, @current_user, ref: @ref)
        response = service.execute(
          @source,
          ignore_skip_ci: true,
          save_on_errors: false,
          content: ci_job_yaml,
          duo_workflow_definition: @duo_workflow_definition,
          suspend_options: suspend_options
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

      def validate_variables_size
        sizes = @workload_definition.variables.to_h do |name, value|
          # The kernel bounds the whole "NAME=VALUE\0" string, not the value on its own.
          [name.to_s, name.to_s.bytesize + value.to_s.bytesize + 2]
        end

        over_limit = sizes.select { |_name, size| size > MAX_VARIABLE_BYTESIZE }
        total = sizes.values.sum

        if over_limit.any?
          Gitlab::AppJsonLogger.error(
            variables_size_payload('Workload job environment exceeds the size limits', sizes, over_limit, total)
          )

          return ServiceResponse.error(
            message: "Error in creating workload: variables over the #{MAX_VARIABLE_BYTESIZE} byte limit: " \
              "#{over_limit.keys.sort.join(', ')}"
          )
        end

        return unless total > WARN_VARIABLES_BYTESIZE

        Gitlab::AppJsonLogger.warn(
          variables_size_payload('Workload job environment is over the total size threshold', sizes, over_limit, total)
        )
        nil
      end

      # Names and sizes only: the values carry OAuth tokens, service tokens and user content.
      # Sizes go under fixed field names as {'name' =>, 'bytesize' =>} objects: variable names are
      # caller-controlled, so hashing on them would inject dynamic keys into the log entry.
      def variables_size_payload(message, sizes, over_limit, total)
        build_structured_payload_labkit(
          message: message,
          Labkit::Fields::GL_PROJECT_ID => @project.id,
          source: @source.to_s,
          duo_workflow_definition: @duo_workflow_definition,
          variables_bytesize: total,
          oversized_variables: over_limit.keys.sort,
          variable_bytesizes: sizes.sort.map { |name, size| { 'name' => name, 'bytesize' => size } }
        )
      end

      # By default a Workload will not get any of the CI variables configured at the project/group/instance level.
      # Setting ci_included_variables option ensures these named variables will later be made available from the CI
      # variables configured at the project/group/instance level.
      def create_included_ci_variables(workload)
        @ci_variables_included.each do |var|
          workload.variable_inclusions.create!(variable_name: var, project: workload.project)
        end
      end

      def suspend_options
        opts = {
          suspend_on_success: @workload_definition.suspend_on_success,
          suspend_on_failure: @workload_definition.suspend_on_failure,
          runtime_environment_key: @workload_definition.runtime_environment_key
        }.compact

        opts.presence
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
