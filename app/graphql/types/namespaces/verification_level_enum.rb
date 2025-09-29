# frozen_string_literal: true

module Types
  module Namespaces
    class VerificationLevelEnum < BaseEnum
      # CiCatalogResourceVerificationLevel is used by both CI Catalog and AI Catalog systems
      # to indicate the verification level of catalog resources
      graphql_name 'CiCatalogResourceVerificationLevel'

      ::Namespaces::VerifiedNamespace::VERIFICATION_LEVELS.each do |level, _|
        value level.upcase, value: level.to_s, description: "The resource is #{level.to_s.titleize}"
      end
    end
  end
end
