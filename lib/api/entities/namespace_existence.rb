# frozen_string_literal: true

module API
  module Entities
    class NamespaceExistence < Grape::Entity
      expose :exists, documentation: { type: 'Boolean' }
      expose :suggests, documentation: { type: 'String', is_array: true, example: 'my-group1' }
    end
  end
end
