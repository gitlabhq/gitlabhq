# frozen_string_literal: true

module API
  module Entities
    class ExternalIssue < Grape::Entity
      expose :title, documentation: { type: 'String', example: 'External Issue PROJ-123' }
      expose :id, documentation: { type: 'String', example: 'PROJ-123' }
    end
  end
end
