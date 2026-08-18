# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        # Object-store keys are case-sensitive, so a segment is downcased only where
        # the database's unique index is under `lower()`. Downcasing `component_name`
        # or `semver` would collide two distinct rows onto one key.
        class ObjectKey
          PREFIX = 'catalog/bundles'

          def initialize(component)
            @component = component
          end

          def dir
            bundled_resource = @component.bundled_resource

            File.join(
              PREFIX,
              bundled_resource.server_fqdn.downcase,
              bundled_resource.full_path.downcase,
              @component.version.semver.to_s
            )
          end

          def filename
            "#{@component.name}.yml"
          end
        end
      end
    end
  end
end
