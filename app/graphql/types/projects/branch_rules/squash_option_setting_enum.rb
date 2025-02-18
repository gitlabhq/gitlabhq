# frozen_string_literal: true

module Types
  module Projects
    module BranchRules
      class SquashOptionSettingEnum < ::Types::BaseEnum
        graphql_name 'SquashOptionSetting'
        description 'Options for default squash behaviour for merge requests'

        value 'NEVER', description: 'Do not allow.', value: 0
        value 'ALLOWED', description: 'Allow.', value: 3
        value 'ENCOURAGED', description: 'Encourage.', value: 2
        value 'ALWAYS', description: 'Require.', value: 1
      end
    end
  end
end
