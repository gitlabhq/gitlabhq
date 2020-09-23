# frozen_string_literal: true

class FeatureFlagsClientEntity < Grape::Entity
  include RequestAwareEntity

  expose :token
end
