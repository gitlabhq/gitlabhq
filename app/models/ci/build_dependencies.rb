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

    def invalid
      [local, cross_pipeline, cross_project].flat_map { |deps| deps.reject(&:valid_dependency?) }
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

        deps = model_class.where(pipeline_id: processable.pipeline_id, partition_id: processable.partition_id).latest
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
    # the current job's pipeline. Only successful jobs can provide artifacts,
    # so we filter the (any-status) hierarchy jobs down to successful ones.
    def cross_pipeline
      existing_cross_pipeline_dependencies.select(&:success?)
    end
    strong_memoize_attr :cross_pipeline

    # Dependencies that are defined by project and ref
    def cross_project
      []
    end

    # All jobs (any status) in the pipeline hierarchy matching the specified cross-pipeline dependencies.
    def existing_cross_pipeline_dependencies
      return [] if expanded_cross_pipeline_dependencies.empty?

      jobs_in_pipeline_hierarchy(expanded_cross_pipeline_dependencies, model_class.latest)
    end
    strong_memoize_attr :existing_cross_pipeline_dependencies

    def jobs_in_pipeline_hierarchy(deps_specifications, scope)
      all_pipeline_ids = []
      all_job_names = []

      deps_specifications.each do |spec|
        all_pipeline_ids << spec[:pipeline]
        all_job_names << spec[:job]
      end

      scope
        .in_pipelines(same_family_pipeline_ids)
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

    def same_family_pipeline_ids
      processable.pipeline.same_family_pipeline_ids
    end
    strong_memoize_attr :same_family_pipeline_ids

    def expanded_cross_pipeline_dependencies
      specified_cross_pipeline_dependencies.filter_map do |spec|
        pipeline = ExpandVariables.expand(spec[:pipeline].to_s, processable_variables).to_i
        # current pipeline is not allowed because local dependencies
        # should be used instead.
        next if pipeline == processable.pipeline_id

        job = ExpandVariables.expand(spec[:job], processable_variables)

        { job: job, pipeline: pipeline, optional: !!spec[:optional] }
      end
    end
    strong_memoize_attr :expanded_cross_pipeline_dependencies

    # Required jobs must succeed. Optional jobs may be absent but must target
    # a valid pipeline, and any existing job must still succeed.
    def valid_cross_pipeline?
      # Current-pipeline dependencies are omitted during expansion but remain invalid here.
      return false unless expanded_cross_pipeline_dependencies.size == specified_cross_pipeline_dependencies.size

      missing_dependencies = expanded_cross_pipeline_dependencies.reject do |spec|
        existing_cross_pipeline_dependencies.any? do |dependency|
          dependency.success? && spec[:pipeline] == dependency.pipeline_id && spec[:job] == dependency.name
        end
      end

      # Missing required dependencies invalidates the build.
      return false if missing_dependencies.any? { |spec| !spec[:optional] }
      return true if missing_dependencies.empty?

      # Missing optional dependencies must still target the same pipeline hierarchy.
      pipeline_ids = missing_dependencies.map { |spec| spec.fetch(:pipeline) }.uniq
      pipelines_in_hierarchy = same_family_pipeline_ids.where(id: pipeline_ids)
      return false unless pipelines_in_hierarchy.count == pipeline_ids.size

      # Optionality permits absent jobs, not existing jobs that failed.
      existing_cross_pipeline_dependencies.all?(&:success?)
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
