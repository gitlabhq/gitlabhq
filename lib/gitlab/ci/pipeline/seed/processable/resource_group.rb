# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        module Processable
          class ResourceGroup < Seed::Base
            include Gitlab::Utils::StrongMemoize

            attr_reader :processable, :resource_group_key

            def initialize(processable, resource_group_key)
              @processable = processable
              @resource_group_key = resource_group_key
            end

            def to_resource
              return unless resource_group_key.present?

              resource_group = processable.project.resource_groups
                .safe_find_or_create_by(key: expanded_resource_group_key)

              resource_group if resource_group.persisted?
            end

            private

            def expanded_resource_group_key
              strong_memoize(:expanded_resource_group_key) do
                ExpandVariables.expand(resource_group_key, -> { variables.sort_and_expand_all })
              end
            end

            def variables
              processable.simple_variables.tap do |variables|
                # Adding persisted environment variables
                if processable.persisted_environment.present?
                  variables.concat(processable.persisted_environment.predefined_variables)
                end
              end
            end
          end
        end
      end
    end
  end
end
