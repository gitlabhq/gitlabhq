# frozen_string_literal: true

module FeatureFlags
  class ClientConfigurationEntity < Grape::Entity
    include RequestAwareEntity

    expose :id
    expose :project_id
  end
end
