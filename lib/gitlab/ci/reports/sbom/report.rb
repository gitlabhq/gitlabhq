# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Report
          attr_reader :components, :sources, :errors

          def initialize
            @components = []
            @errors = []
            @sources = []
          end

          def add_error(error)
            errors << error
          end

          def add_source(source)
            sources << Source.new(source)
          end

          def add_component(component)
            components << Component.new(component)
          end
        end
      end
    end
  end
end
