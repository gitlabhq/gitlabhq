# frozen_string_literal: true

module API
  module Entities
    class NamespaceExistence < Grape::Entity
      expose :exists, documentation: { type: 'boolean' }
      expose :suggests, documentation: { type: 'string', is_array: true, example: 'my-group1' }
    end
  end
end
