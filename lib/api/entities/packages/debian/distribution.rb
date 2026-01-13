# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Debian
        class Distribution < Grape::Entity
          expose :id, documentation: { type: 'Integer', example: 1 }
          expose :codename, documentation: { type: 'String', example: 'sid' }
          expose :suite, documentation: { type: 'String', example: 'unstable' }
          expose :origin, documentation: { type: 'String', example: 'Grep' }
          expose :label, documentation: { type: 'String', example: 'grep.be' }
          expose :version, documentation: { type: 'String', example: '12' }
          expose :description, documentation: { type: 'String', example: 'My description' }
          expose :valid_time_duration_seconds, documentation: { type: 'Integer', example: 604800 }

          expose :component_names, as: :components, documentation: { is_array: true, type: 'String', example: 'main' }
          expose :architecture_names, as: :architectures,
            documentation: { is_array: true, type: 'String', example: 'amd64' }
        end
      end
    end
  end
end
