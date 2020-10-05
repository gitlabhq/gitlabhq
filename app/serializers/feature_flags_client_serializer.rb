# frozen_string_literal: true

class FeatureFlagsClientSerializer < BaseSerializer
  entity FeatureFlagsClientEntity

  def represent_token(resource, opts = {})
    represent(resource, only: [:token])
  end
end
