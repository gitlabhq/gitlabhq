# frozen_string_literal: true

module API
  module Entities
    class UnleashLegacyStrategy < Grape::Entity
      expose :name do |strategy|
        strategy['name']
      end
      expose :parameters do |strategy|
        strategy['parameters']
      end
    end
  end
end
