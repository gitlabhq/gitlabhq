# frozen_string_literal: true

module API
  module Entities
    # Simple representation for endpoints that returns a trivial success response.
    class BasicSuccess < Grape::Entity
      expose :success, documentation: { type: 'boolean' } do
        true
      end
    end
  end
end
