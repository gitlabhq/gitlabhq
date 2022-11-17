# frozen_string_literal: true

module API
  module Entities
    class FeatureFlag < Grape::Entity
      class Scope < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :environment_scope, documentation: { type: 'string', example: 'production' }
      end
    end
  end
end
