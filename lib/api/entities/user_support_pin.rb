# frozen_string_literal: true

module API
  module Entities
    class UserSupportPin < Grape::Entity
      expose :pin, documentation: { type: 'string', desc: 'The security PIN' }
      expose :expires_at,
        documentation: { type: 'string', format: 'date-time', desc: 'The expiration time of the PIN' }
    end
  end
end
