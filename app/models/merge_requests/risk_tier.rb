# frozen_string_literal: true

module MergeRequests
  module RiskTier
    extend DeclarativeEnum

    key :tier
    name 'MergeRequestRiskTier'
    description 'Risk tier derived from a merge request risk score.'

    define do
      low value: 0, description: N_('Low risk.')
      medium value: 1, description: N_('Medium risk.')
      high value: 2, description: N_('High risk.')
      critical value: 3, description: N_('Critical risk.')
    end
  end
end
