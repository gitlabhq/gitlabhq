# frozen_string_literal: true

module Types
  module Integrations
    class IntegrationTypeEnum < BaseEnum
      graphql_name 'IntegrationType'
      description 'Integration Names'

      value 'BEYOND_IDENTITY', description: 'Beyond Identity.', value: 'beyond_identity'
    end
  end
end
