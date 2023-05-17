# frozen_string_literal: true

module Types
  module Ci
    module Config
      class IncludeTypeEnum < BaseEnum
        graphql_name 'CiConfigIncludeType'
        description 'Include type.'

        value 'remote', description: 'Remote include.', value: :remote
        value 'local', description: 'Local include.', value: :local
        value 'file', description: 'Project file include.', value: :file
        value 'template', description: 'Template include.', value: :template
        value 'component', description: 'Component include.', value: :component
      end
    end
  end
end
