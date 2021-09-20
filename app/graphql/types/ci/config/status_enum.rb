# frozen_string_literal: true

module Types
  module Ci
    module Config
      class StatusEnum < BaseEnum
        graphql_name 'CiConfigStatus'
        description 'Values for YAML processor result'

        value 'VALID', 'Configuration file is valid.', value: :valid
        value 'INVALID', 'Configuration file is not valid.', value: :invalid
      end
    end
  end
end
