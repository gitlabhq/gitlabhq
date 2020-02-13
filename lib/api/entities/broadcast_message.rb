# frozen_string_literal: true

module API
  module Entities
    class BroadcastMessage < Grape::Entity
      expose :id, :message, :starts_at, :ends_at, :color, :font
      expose :active?, as: :active
    end
  end
end
