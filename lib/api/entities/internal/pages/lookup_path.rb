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
            :unique_host,
            :root_directory,
            :primary_domain,
            :root_namespace_id
        end
      end
    end
  end
end
