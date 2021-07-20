# frozen_string_literal: true

module Ci
  class BuildDependencies
    include ::Gitlab::Utils::StrongMemoize

    attr_reader :processable

    def initialize(processable)
      @processable = processable
    end

    def all
      (local + cross_pipeline + cross_project).uniq
    end

    def invalid_local
      local.reject(&:valid_dependency?)
    end

    def valid?
      valid_local? && valid_cross_pipeline? && valid_cross_project?
    end

    private

    # Dependencies can only be of Ci::Build type because only builds
    # can create artifacts
    def model_class
      ::Ci::Build
    end

    # Dependencies local to the given pipeline
    def local
      strong_memoize(:local) do
        next [] if no_local_dependencies_specified?
        next [] unless processable.pipeline_id # we don't have any dependency when creating the pipeline

        deps = model_class.where(pipeline_id: processable.pipeline_id).latest
        deps = find_dependencies(processable, deps)

        from_dependencies(deps).to_a
      end
    end

    def find_dependencies(processable, deps)
      if processable.scheduling_type_dag?
        from_needs(deps)
      else
        from_previous_stages(deps)
      end
    end

    # Dependencies from the same parent-pipeline hierarchy excluding
    # the current job's pipeline
    def cross_pipeline
      strong_memoize(:cross_pipeline) do
        fetch_dependencies_in_hierarchy
      end
    end

    # Dependencies that are defined by project and ref
    def cross_project
      []
    end

    def fetch_dependencies_in_hierarchy
      deps_specifications = specified_cross_pipeline_dependencies
      return [] if deps_specifications.empty?

      deps_specifications = expand_variables_and_validate(deps_specifications)
      jobs_in_pipeline_hierarchy(deps_specifications)
    end

    def jobs_in_pipeline_hierarchy(deps_specifications)
      all_pipeline_ids = []
      all_job_names = []

      deps_specifications.each do |spec|
        all_pipeline_ids << spec[:pipeline]
        all_job_names << spec[:job]
      end

      model_class.latest.success
        .in_pipelines(processable.pipeline.same_family_pipeline_ids)
        .in_pipelines(all_pipeline_ids.uniq)
        .by_name(all_job_names.uniq)
        .select do |dependency|
          # the query may not return exact matches pipeline-job, so we filter
          # them separately.
          deps_specifications.find do |spec|
            spec[:pipeline] == dependency.pipeline_id &&
              spec[:job] == dependency.name
          end
        end
    end

    def expand_variables_and_validate(specifications)
      specifications.map do |spec|
        pipeline = ExpandVariables.expand(spec[:pipeline].to_s, processable_variables).to_i
        # current pipeline is not allowed because local dependencies
        # should be used instead.
        next if pipeline == processable.pipeline_id

        job = ExpandVariables.expand(spec[:job], processable_variables)

        { job: job, pipeline: pipeline }
      end.compact
    end

    def valid_cross_pipeline?
      cross_pipeline.size == specified_cross_pipeline_dependencies.size
    end

    def valid_local?
      local.all?(&:valid_dependency?)
    end

    def valid_cross_project?
      true
    end

    def project
      processable.project
    end

    def no_local_dependencies_specified?
      processable.options[:dependencies]&.empty?
    end

    def from_previous_stages(scope)
      scope.before_stage(processable.stage_idx)
    end

    def from_needs(scope)
      needs_names = processable.needs.artifacts.select(:name)
      scope.where(name: needs_names)
    end

    def from_dependencies(scope)
      return scope unless processable.options[:dependencies].present?

      scope.where(name: processable.options[:dependencies])
    end

    def processable_variables
      -> { processable.simple_variables_without_dependencies }
    end

    def specified_cross_pipeline_dependencies
      strong_memoize(:specified_cross_pipeline_dependencies) do
        specified_cross_dependencies.select { |dep| dep[:pipeline] && dep[:artifacts] }
      end
    end

    def specified_cross_dependencies
      Array(processable.options[:cross_dependencies])
    end
  end
end

Ci::BuildDependencies.prepend_mod_with('Ci::BuildDependencies')
