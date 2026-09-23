# frozen_string_literal: true

module Gitlab
  module Routing
    module OrganizationsHelper
      extend ActiveSupport::Concern

      # Only strips the prefix when a further segment follows: /o/:organization_path
      # alone is the Organization's own page, not a scoped version of another path.
      ORGANIZATION_SCOPE_PREFIX_REGEX = %r{\A/o/#{Gitlab::PathRegex.organization_route_regex}(?=/)}

      # Check if this is an organization route (/o/org-path/...)
      def organization_scoped_route?(path)
        return false unless path

        path.start_with?('/o/')
      end

      # The same path without its /o/:organization_path prefix, so that scoped
      # and unscoped URLs of one resource can be treated as the same. Assumes
      # namespace paths are unique instance-wide; once they are unique only per
      # Organization, callers must also key on the Organization, see
      # https://gitlab.com/gitlab-org/gitlab/-/work_items/630141
      def unscoped_path(path)
        return path unless organization_scoped_route?(path)

        path.sub(ORGANIZATION_SCOPE_PREFIX_REGEX, '')
      end

      module_function :organization_scoped_route?, :unscoped_path
    end
  end
end
