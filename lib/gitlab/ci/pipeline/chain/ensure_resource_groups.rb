# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class EnsureResourceGroups < Chain::Base
          def perform!
            pipeline.stages.map(&:statuses).flatten.each(&method(:ensure_resource_group))
          end

          def break?
            false
          end

          private

          def ensure_resource_group(processable)
            return unless processable.is_a?(::Ci::Processable)

            key = processable.options.delete(:resource_group_key)

            resource_group = ::Gitlab::Ci::Pipeline::Seed::Processable::ResourceGroup
              .new(processable, key).to_resource

            processable.resource_group = resource_group
          end
        end
      end
    end
  end
end
