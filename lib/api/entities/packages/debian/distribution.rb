# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Debian
        class Distribution < Grape::Entity
          expose :id, documentation: { type: 'integer', example: 1 }
          expose :codename, documentation: { type: 'string', example: 'sid' }
          expose :suite, documentation: { type: 'string', example: 'unstable' }
          expose :origin, documentation: { type: 'string', example: 'Grep' }
          expose :label, documentation: { type: 'string', example: 'grep.be' }
          expose :version, documentation: { type: 'string', example: '12' }
          expose :description, documentation: { type: 'string', example: 'My description' }
          expose :valid_time_duration_seconds, documentation: { type: 'integer', example: 604800 }

          expose :component_names, as: :components, documentation: { is_array: true, type: 'string', example: 'main' }
          expose :architecture_names, as: :architectures,
            documentation: { is_array: true, type: 'string', example: 'amd64' }
        end
      end
    end
  end
end
