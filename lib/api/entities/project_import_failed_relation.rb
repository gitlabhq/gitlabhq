# frozen_string_literal: true

module API
  module Entities
    class ProjectImportFailedRelation < Grape::Entity
      expose :id, documentation: { type: 'String', example: 1 }
      expose :created_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
      expose :exception_class, documentation: { type: 'String', example: 'StandardError' }
      expose :source, documentation: { type: 'String', example: 'ImportRepositoryWorker' }

      expose :exception_message, documentation: { type: 'String' } do |_|
        nil
      end

      expose :relation_key, as: :relation_name, documentation: { type: 'String', example: 'issues' }
      expose :relation_index, as: :line_number, documentation: { type: 'Integer', example: 1 }
    end
  end
end
