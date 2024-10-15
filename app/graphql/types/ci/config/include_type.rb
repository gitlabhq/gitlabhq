# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    module Config
      class IncludeType < BaseObject
        graphql_name 'CiConfigInclude'

        field :type,
          Types::Ci::Config::IncludeTypeEnum,
          null: true,
          description: 'Include type.'

        field :location,
          GraphQL::Types::String,
          null: true,
          description: 'File location. It can be masked if it contains masked variables. For example, ' \
            '`".gitlab/ci/build-images.gitlab-ci.yml"`.'

        field :blob,
          GraphQL::Types::String,
          null: true,
          description: 'File blob location. It can be masked if it contains masked variables. For example, ' \
            '`"https://gitlab.com/gitlab-org/gitlab/-/blob/e52d6d0246d7375291850e61f0abc101fbda9dc2' \
            '/.gitlab/ci/build-images.gitlab-ci.yml"`.'

        field :raw,
          GraphQL::Types::String,
          null: true,
          description: 'File raw location. It can be masked if it contains masked variables. For example, ' \
            '`"https://gitlab.com/gitlab-org/gitlab/-/raw/e52d6d0246d7375291850e61f0abc101fbda9dc2' \
            '/.gitlab/ci/build-images.gitlab-ci.yml"`.'

        field :extra, # rubocop:disable Graphql/JSONType
          GraphQL::Types::JSON,
          null: true,
          description: 'Extra information for the `include`, which can contain `job_name`, `project`, and `ref`. ' \
            'Values can be masked if they contain masked variables.'

        field :context_project,
          GraphQL::Types::String,
          null: true,
          description: 'Current project scope, e.g., "gitlab-org/gitlab".'

        field :context_sha,
          GraphQL::Types::String,
          null: true,
          description: 'Current sha scope.'
      end
    end
  end
end
