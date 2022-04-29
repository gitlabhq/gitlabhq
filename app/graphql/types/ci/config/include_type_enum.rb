# frozen_string_literal: true

module Types
  module Ci
    module Config
      class IncludeTypeEnum < BaseEnum
        graphql_name 'CiConfigIncludeType'
        description 'Include type.'

        value 'remote', description: 'Remote include.', value: :remote
        value 'local', description: 'Local include.', value: :local
        value 'project', description: 'Project include.', value: :project
        value 'template', description: 'Template include.', value: :template
      end
    end
  end
end
