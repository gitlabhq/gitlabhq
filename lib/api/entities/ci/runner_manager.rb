# frozen_string_literal: true

module API
  module Entities
    module Ci
      class RunnerManager < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 8 }
        expose :system_xid, as: :system_id, documentation: { type: 'string', example: 'runner-1' }
        expose :version, documentation: { type: 'string', example: '16.11.0' }
        expose :revision, documentation: { type: 'string', example: '91a27b2a' }
        expose :platform, documentation: { type: 'string', example: 'linux' }
        expose :architecture, documentation: { type: 'string', example: 'amd64' }
        expose :created_at, documentation: { type: 'string', example: '2023-10-24T01:27:06.549Z' }
        expose :contacted_at, documentation: { type: 'string', example: '2023-10-24T01:27:06.549Z' }
        expose :ip_address, documentation: { type: 'string', example: '127.0.0.1' }
        expose :status, documentation: { type: 'string', example: 'online' }
      end
    end
  end
end
