# frozen_string_literal: true

module API
  module Entities
    module System
      class BroadcastMessage < Grape::Entity
        expose :id, documentation: { type: 'Integer' }
        expose :message, :starts_at, :ends_at, :color, :font, :target_access_levels, :target_path,
          :broadcast_type, :theme
        expose :dismissable, documentation: { type: 'Boolean' }
        expose :active?, as: :active, documentation: { type: 'Boolean' }
      end
    end
  end
end
