# frozen_string_literal: true

module API
  module Helpers
    module VariablesHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_group_variable_params_ee do
      end

      def filter_variable_parameters(_, params)
        params # Overridden in EE
      end

      def find_variable(owner, params)
        variables = ::Ci::VariablesFinder.new(owner, params).execute.to_a

        return variables.first unless variables.many? # rubocop: disable CodeReuse/ActiveRecord

        conflict!("There are multiple variables with provided parameters. Please use 'filter[environment_scope]'")
      end
    end
  end
end

API::Helpers::VariablesHelpers.prepend_mod_with('API::Helpers::VariablesHelpers')
