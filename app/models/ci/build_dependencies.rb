# frozen_string_literal: true

module Ci
  class BuildDependencies
    attr_reader :processable

    def initialize(processable)
      @processable = processable
    end

    def all
      (local + cross_project).uniq
    end

    # Dependencies local to the given pipeline
    def local
      return [] if no_local_dependencies_specified?

      deps = model_class.where(pipeline_id: processable.pipeline_id).latest
      deps = from_previous_stages(deps)
      deps = from_needs(deps)
      deps = from_dependencies(deps)
      deps
    end

    # Dependencies that are defined by project and ref
    def cross_project
      []
    end

    def invalid_local
      local.reject(&:valid_dependency?)
    end

    def valid?
      valid_local? && valid_cross_project?
    end

    private

    # Dependencies can only be of Ci::Build type because only builds
    # can create artifacts
    def model_class
      ::Ci::Build
    end

    def valid_local?
      return true if Feature.enabled?(:ci_disable_validates_dependencies)

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
      return scope unless processable.scheduling_type_dag?

      needs_names = processable.needs.artifacts.select(:name)
      scope.where(name: needs_names)
    end

    def from_dependencies(scope)
      return scope unless processable.options[:dependencies].present?

      scope.where(name: processable.options[:dependencies])
    end
  end
end

Ci::BuildDependencies.prepend_if_ee('EE::Ci::BuildDependencies')
