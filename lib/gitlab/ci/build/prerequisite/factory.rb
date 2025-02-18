# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Prerequisite
        class Factory
          attr_reader :build

          def self.prerequisites
            [KubernetesNamespace, ManagedResource]
          end

          def initialize(build)
            @build = build
          end

          def unmet
            build_prerequisites.select(&:unmet?)
          end

          private

          def build_prerequisites
            self.class.prerequisites.map do |prerequisite|
              prerequisite.new(build)
            end
          end
        end
      end
    end
  end
end
