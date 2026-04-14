# frozen_string_literal: true

module API
  module Entities
    module WorkItems
      module Features
        class DetailEntity < Grape::Entity
          include CommonExposures
        end
      end
    end
  end
end

::API::Entities::WorkItems::Features::DetailEntity.prepend_mod
