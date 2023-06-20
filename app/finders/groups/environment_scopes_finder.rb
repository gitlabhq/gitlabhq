# frozen_string_literal: true

# Groups::EnvironmentsScopesFinder
#
# Arguments:
#   group
#   params:
#     search: string
#
module Groups
  class EnvironmentScopesFinder
    DEFAULT_ENVIRONMENT_SCOPES_LIMIT = 100

    def initialize(group:, params: {})
      @group = group
      @params = params
    end

    EnvironmentScope = Struct.new(:name)

    def execute
      variables = group.variables
      variables = by_name(variables)
      variables = by_search(variables)
      variables = variables.limit(DEFAULT_ENVIRONMENT_SCOPES_LIMIT)
      environment_scope_names = variables.environment_scope_names
      environment_scope_names.map { |environment_scope| EnvironmentScope.new(environment_scope) }
    end

    private

    attr_reader :group, :params

    def by_name(group_variables)
      if params[:name].present?
        group_variables.by_environment_scope(params[:name])
      else
        group_variables
      end
    end

    def by_search(group_variables)
      if params[:search].present?
        group_variables.for_environment_scope_like(params[:search])
      else
        group_variables
      end
    end
  end
end
