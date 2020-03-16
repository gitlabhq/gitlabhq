# frozen_string_literal: true

module API
  module Entities
    module Internal
      module Pages
        class LookupPath < Grape::Entity
          expose :project_id, :access_control,
            :source, :https_only, :prefix
        end
      end
    end
  end
end
