# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Component
          attr_reader :component_type, :name, :version

          def initialize(component = {})
            @component_type = component['type']
            @name = component['name']
            @version = component['version']
          end
        end
      end
    end
  end
end
