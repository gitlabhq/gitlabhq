# frozen_string_literal: true

module API
  module Entities
    class PushEventPayload < Grape::Entity
      expose :commit_count, documentation: { type: 'Integer', example: 1 }
      expose :action, documentation: { type: 'String', example: 'pushed' }
      expose :ref_type, documentation: { type: 'String', example: 'branch' }
      expose :commit_from, documentation: { type: 'String', example: '50d4420237a9de7be1304607147aec22e4a14af7' }
      expose :commit_to, documentation: { type: 'String', example: 'c5feabde2d8cd023215af4d2ceeb7a64839fc428' }
      expose :ref, documentation: { type: 'String', example: 'master' }
      expose :commit_title, documentation: { type: 'String', example: 'Add simple search to projects in public area' }
      expose :ref_count, documentation: { type: 'Integer', example: 1 }
    end
  end
end
