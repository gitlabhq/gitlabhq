# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class Entity < Grape::Entity
          include CommonExposures
        end
      end
    end
  end
end

::API::Entities::WorkItems::Features::Entity.prepend_mod
