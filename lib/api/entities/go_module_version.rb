# frozen_string_literal: true

module API
  module Entities
    class GoModuleVersion < Grape::Entity
      expose :name, as: 'Version'
      expose :time, as: 'Time'
    end
  end
end
