# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class Report
          attr_reader :components, :source, :errors

          def initialize
            @components = []
            @errors = []
          end

          def valid?
            errors.empty?
          end

          def add_error(error)
            errors << error
          end

          def set_source(source)
            self.source = source
          end

          def add_component(component)
            components << component
          end

          private

          attr_writer :source
        end
      end
    end
  end
end
