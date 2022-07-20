# frozen_string_literal: true

module Types
  module Ci
    class VariableTypeEnum < BaseEnum
      graphql_name 'CiVariableType'

      ::Ci::Variable.variable_types.keys.each do |variable_type|
        value variable_type.upcase, value: variable_type, description: "#{variable_type.humanize} type."
      end
    end
  end
end
