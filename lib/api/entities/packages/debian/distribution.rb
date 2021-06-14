# frozen_string_literal: true

module API
  module Entities
    module Packages
      module Debian
        class Distribution < Grape::Entity
          expose :id
          expose :codename
          expose :suite
          expose :origin
          expose :label
          expose :version
          expose :description
          expose :valid_time_duration_seconds

          expose :component_names, as: :components
          expose :architecture_names, as: :architectures
        end
      end
    end
  end
end
