# frozen_string_literal: true

module Gitlab
  module Ci
    module Catalog
      module Bundle
        # Object-store keys are case-sensitive. The natural key columns are stored
        # lowercase, but `component_name` and `semver` are not: downcasing either
        # would collide two distinct rows onto one key.
        class ObjectKey
          PREFIX = 'catalog/bundles'

          def self.dir_for(bundled_resource, semver)
            File.join(
              PREFIX,
              bundled_resource.server_fqdn.downcase,
              bundled_resource.full_path.downcase,
              semver.to_s
            )
          end

          def initialize(component)
            @component = component
          end

          def dir
            self.class.dir_for(@component.bundled_resource, @component.version.semver)
          end

          def filename
            "#{@component.name}.yml"
          end
        end
      end
    end
  end
end
