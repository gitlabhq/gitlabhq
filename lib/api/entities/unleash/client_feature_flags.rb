# frozen_string_literal: true

module API
  module Entities
    module Unleash
      class ClientFeatureFlags < Grape::Entity
        expose :unleash_api_version, as: :version
        expose :unleash_api_features, as: :features, using: ::API::Entities::UnleashFeature
      end
    end
  end
end
