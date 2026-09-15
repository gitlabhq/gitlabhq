# frozen_string_literal: true

module Types
  module Ci
    module Config
      class IncludeTypeEnum < BaseEnum
        graphql_name 'CiConfigIncludeType'
        description 'Include type.'

        value 'remote', description: 'Remote include.', value: :remote
        value 'local', description: 'Local include.', value: :local
        # The internal `:project` include type is exposed as `file` to keep the GraphQL API stable.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/600839.
        value 'file', description: 'Project file include.', value: :project
        value 'template', description: 'Template include.', value: :template
        value 'component', description: 'Component include.', value: :component
      end
    end
  end
end
