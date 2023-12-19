# frozen_string_literal: true

module API
  module Entities
    class BasicRepositoryStorageMove < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 1 }
      expose :created_at, documentation: { type: 'dateTime', example: '2020-05-07T04:27:17.234Z' }
      expose :human_state_name, as: :state, documentation: { type: 'string', example: 'scheduled' }
      expose :source_storage_name, documentation: { type: 'string', example: 'default' }
      expose :destination_storage_name, documentation: { type: 'string', example: 'storage1' }
      expose :error_message, documentation: { type: 'string', example: 'Failed to move repository' }
    end
  end
end
