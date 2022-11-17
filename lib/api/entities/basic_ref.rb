# frozen_string_literal: true

module API
  module Entities
    class BasicRef < Grape::Entity
      expose :type,  documentation: { type: 'string', example: 'tag' }
      expose :name,  documentation: { type: 'string', example: 'v1.1.0' }
    end
  end
end
