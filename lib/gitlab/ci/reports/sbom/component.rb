# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Component
          attr_reader :component_type, :name, :version

          def initialize(type:, name:, version:)
            @component_type = type
            @name = name
            @version = version
          end
        end
      end
    end
  end
end
