# frozen_string_literal: true

module API
  module Entities
    class UserSupportPin < Grape::Entity
      expose :pin, documentation: { type: 'String', desc: 'The security PIN' }
      expose :expires_at,
        documentation: { type: 'String', format: 'date-time', desc: 'The expiration time of the PIN' }
    end
  end
end
