# frozen_string_literal: true

module API
  module Entities
    class BasicRef < Grape::Entity
      expose :type,  documentation: { type: 'String', example: 'tag' }
      expose :name,  documentation: { type: 'String', example: 'v1.1.0' }
    end
  end
end
