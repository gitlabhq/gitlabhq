# frozen_string_literal: true

module API
  module Entities
    class Contributor < Grape::Entity
      expose :name, documentation: { example: 'John Doe' }
      expose :email, documentation: { example: 'johndoe@example.com' }
      expose :commits, documentation: { type: 'integer', example: 117 }
      expose :additions, documentation: { type: 'integer', example: 3 }
      expose :deletions, documentation: { type: 'integer', example: 5 }
    end
  end
end
