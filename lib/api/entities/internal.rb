# frozen_string_literal: true

module API
  module Entities
    module Internal
      module Pages
        class LookupPath < Grape::Entity
          expose :project_id, :access_control,
            :source, :https_only, :prefix
        end

        class VirtualDomain < Grape::Entity
          expose :certificate, :key
          expose :lookup_paths, using: LookupPath
        end
      end
    end
  end
end
