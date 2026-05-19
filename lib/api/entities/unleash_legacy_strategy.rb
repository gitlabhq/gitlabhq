# frozen_string_literal: true

module API
  module Entities
    class UnleashLegacyStrategy < Grape::Entity
      expose :name, documentation: { type: 'String' } do |strategy|
        strategy['name']
      end
      expose :parameters, documentation: { type: 'Hash' } do |strategy|
        strategy['parameters']
      end
    end
  end
end
