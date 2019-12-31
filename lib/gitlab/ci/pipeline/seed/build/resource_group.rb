# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Build
          class ResourceGroup < Seed::Base
            include Gitlab::Utils::StrongMemoize

            attr_reader :build, :resource_group_key

            def initialize(build, resource_group_key)
              @build = build
              @resource_group_key = resource_group_key
            end

            def to_resource
              return unless Feature.enabled?(:ci_resource_group, build.project, default_enabled: true)
              return unless resource_group_key.present?

              resource_group = build.project.resource_groups
                .safe_find_or_create_by(key: expanded_resource_group_key)

              resource_group if resource_group.persisted?
            end

            private

            def expanded_resource_group_key
              strong_memoize(:expanded_resource_group_key) do
                ExpandVariables.expand(resource_group_key, -> { build.simple_variables })
              end
            end
          end
        end
      end
    end
  end
end
