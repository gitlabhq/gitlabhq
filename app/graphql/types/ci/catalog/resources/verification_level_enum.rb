# frozen_string_literal: true

module Types
  module Ci
    module Catalog
      module Resources
        # rubocop: disable Graphql/AuthorizeTypes -- Authorization handled by ResourceType
        class VerificationLevelEnum < BaseEnum
          graphql_name 'CiCatalogResourceVerificationLevel'

          ::Ci::Catalog::VerifiedNamespace::VERIFICATION_LEVELS.each do |level, _|
            value level.upcase, value: level.to_s, description: "The resource is #{level.to_s.titleize}"
          end
        end
        # rubocop: enable Graphql/AuthorizeTypes
      end
    end
  end
end
