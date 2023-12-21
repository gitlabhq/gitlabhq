# frozen_string_literal: true

module Gitlab
  module Ci
    module Parsers
      module Sbom
        module Source
          class Trivy < BaseSource
            private

            def type
              :trivy
            end
          end
        end
      end
    end
  end
end
