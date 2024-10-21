# frozen_string_literal: true

module API
  module Entities
    module System
      class BroadcastMessage < Grape::Entity
        expose :id, :message, :starts_at, :ends_at, :color, :font, :target_access_levels, :target_path,
          :broadcast_type, :dismissable, :theme
        expose :active?, as: :active
      end
    end
  end
end
