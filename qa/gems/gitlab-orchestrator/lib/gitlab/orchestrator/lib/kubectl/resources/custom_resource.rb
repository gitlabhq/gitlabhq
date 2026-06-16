# frozen_string_literal: true

module Gitlab
  module Orchestrator
    module Kubectl
      module Resources
        class CustomResource < Base
          def initialize(resource_name, manifest)
            super(resource_name)

            @manifest = manifest
          end

          def json
            @json ||= @manifest.to_json
          end
        end
      end
    end
  end
end
