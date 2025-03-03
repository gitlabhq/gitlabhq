# frozen_string_literal: true

module API
  module Entities
    # rubocop:disable Layout/LineLength -- `desc` is too long
    class RepositoryHealth < Grape::Entity
      class References < Grape::Entity
        expose :loose_count,
          documentation: { type: 'integer', desc: 'Number of loose references in the repository.' }
        expose :packed_size,
          documentation: { type: 'integer', desc: 'Size in bytes of packed references in the repository.' }
        expose :reference_backend,
          documentation: { type: 'string',
                           desc: "Type of backend used to store references. Either 'REFERENCE_BACKEND_REFTABLE' or 'REFERENCE_BACKEND_FILES'." }
      end

      class Objects < Grape::Entity
        expose :size,
          documentation: { type: 'integer', desc: 'Size in bytes of all objects in the repository.' }
        expose :recent_size,
          documentation: { type: 'integer',
                           desc: 'Size in bytes of all recent objects in the repository. Recent objects are those which are reachable.' }
        expose :stale_size,
          documentation: { type: 'integer',
                           desc: 'Size in bytes of all stale objects in the repository. Stale objects are those which are unreachable and may be deleted during housekeeping.' }
        expose :keep_size,
          documentation: { type: 'integer', desc: 'Size in bytes of all packfiles with the .keep extension.' }
      end

      expose :size, documentation: { type: 'integer', desc: 'Repository size in bytes.' }
      expose :references, using: References
      expose :objects, using: Objects
      expose :updated_at, documentation: { type: 'dateTime', example: '2025-02-24T09:05:50.355Z' }
    end
    # rubocop:enable Layout/LineLength
  end
end
