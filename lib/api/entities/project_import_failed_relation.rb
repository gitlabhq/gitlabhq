# frozen_string_literal: true

module API
  module Entities
    class ProjectImportFailedRelation < Grape::Entity
      expose :id, documentation: { type: 'string', example: 1 }
      expose :created_at, documentation: { type: 'dateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :exception_class, documentation: { type: 'string', example: 'StandardError' }
      expose :source, documentation: { type: 'string', example: 'ImportRepositoryWorker' }

      expose :exception_message, documentation: { type: 'string' } do |_|
        nil
      end

      expose :relation_key, as: :relation_name, documentation: { type: 'string', example: 'issues' }
      expose :relation_index, as: :line_number, documentation: { type: 'integer', example: 1 }
    end
  end
end
