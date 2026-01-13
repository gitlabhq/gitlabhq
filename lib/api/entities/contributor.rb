# frozen_string_literal: true

module API
  module Entities
    class Contributor < Grape::Entity
      expose :name, documentation: { example: 'John Doe' }
      expose :email, documentation: { example: 'johndoe@example.com' }
      expose :commits, documentation: { type: 'Integer', example: 117 }
      expose :additions, documentation: { type: 'Integer', example: 3 }
      expose :deletions, documentation: { type: 'Integer', example: 5 }
    end
  end
end
