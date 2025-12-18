# frozen_string_literal: true

module API
  module Entities
    class BasicRepositoryStorageMove < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 1 }
      expose :created_at, documentation: { type: 'DateTime', example: '2020-05-07T04:27:17.234Z' }
      expose :human_state_name, as: :state, documentation: { type: 'String', example: 'scheduled' }
      expose :source_storage_name, documentation: { type: 'String', example: 'default' }
      expose :destination_storage_name, documentation: { type: 'String', example: 'storage1' }
      expose :error_message, documentation: { type: 'String', example: 'Failed to move repository' }
    end
  end
end
