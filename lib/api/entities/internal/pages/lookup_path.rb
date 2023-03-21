# frozen_string_literal: true

module API
  module Entities
    module Internal
      module Pages
        class LookupPath < Grape::Entity
          expose :access_control,
            :https_only,
            :prefix,
            :project_id,
            :source,
            :unique_url
        end
      end
    end
  end
end
