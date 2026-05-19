# frozen_string_literal: true

module API
  module Entities
    class UnleashStrategy < Grape::Entity
      expose :name, documentation: { type: 'String' }
      expose :parameters, documentation: { type: 'Hash' }
    end
  end
end
