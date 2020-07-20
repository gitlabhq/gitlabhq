# frozen_string_literal: true

module Ci
  class VariablesFinder
    attr_reader :project, :params

    def initialize(project, params)
      @project, @params = project, params

      raise ArgumentError, 'Please provide params[:key]' if params[:key].blank?
    end

    def execute
      variables = project.variables
      variables = by_key(variables)
      variables = by_environment_scope(variables)
      variables
    end

    private

    def by_key(variables)
      variables.by_key(params[:key])
    end

    def by_environment_scope(variables)
      environment_scope = params.dig(:filter, :environment_scope)
      environment_scope.present? ? variables.by_environment_scope(environment_scope) : variables
    end
  end
end
