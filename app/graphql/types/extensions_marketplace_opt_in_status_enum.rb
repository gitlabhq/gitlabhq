# frozen_string_literal: true

module Types
  class ExtensionsMarketplaceOptInStatusEnum < BaseEnum
    graphql_name 'ExtensionsMarketplaceOptInStatus'
    description 'Values for status of the Web IDE Extension Marketplace opt-in for the user'

    UserPreference.extensions_marketplace_opt_in_statuses.each_key do |field|
      value field.upcase, value: field, description: "Web IDE Extension Marketplace opt-in status: #{field.upcase}."
    end
  end
end
