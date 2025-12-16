# frozen_string_literal: true

module API
  module Entities
    module Import
      module Offline
        class Export < Grape::Entity
          expose :id, documentation: { type: 'Integer', example: 1 }
          expose :status_name, as: :status, documentation: {
            type: 'String', example: 'finished', values: %w[created started finished failed]
          }
          expose :source_hostname, documentation: { type: 'String', example: 'https://source.example.com/' }
          expose :created_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
          expose :updated_at, documentation: { type: 'DateTime', example: '2012-05-28T04:42:42-07:00' }
          expose :has_failures, documentation: { type: 'Boolean', example: false }
        end
      end
    end
  end
end
