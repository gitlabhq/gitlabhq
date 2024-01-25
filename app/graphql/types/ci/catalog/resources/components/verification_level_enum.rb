# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        module Components
          # rubocop: disable Graphql/AuthorizeTypes -- Authorization handled by ResourceType
          class VerificationLevelEnum < BaseEnum
            graphql_name 'CiCatalogResourceComponentVerificationLevel'

            value 'UNVERIFIED', value: 'unverified', description: 'Component is unverified.'
            value 'GITLAB', value: 'gitlab', description: 'Component is maintained by GitLab.'
          end
          # rubocop: enable Graphql/AuthorizeTypes
        end
      end
    end
  end
end
