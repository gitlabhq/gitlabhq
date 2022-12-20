# frozen_string_literal: true

module API
  module Entities
    class PushEventPayload < Grape::Entity
      expose :commit_count, documentation: { type: 'integer', example: 1 }
      expose :action, documentation: { type: 'string', example: 'pushed' }
      expose :ref_type, documentation: { type: 'string', example: 'branch' }
      expose :commit_from, documentation: { type: 'string', example: '50d4420237a9de7be1304607147aec22e4a14af7' }
      expose :commit_to, documentation: { type: 'string', example: 'c5feabde2d8cd023215af4d2ceeb7a64839fc428' }
      expose :ref, documentation: { type: 'string', example: 'master' }
      expose :commit_title, documentation: { type: 'string', example: 'Add simple search to projects in public area' }
      expose :ref_count, documentation: { type: 'integer', example: 1 }
    end
  end
end
