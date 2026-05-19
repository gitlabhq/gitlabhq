# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Checks for direct use of organization-scoped URL route helpers.
      #
      # All routes are cloned under the `/o/:organization_path` scope, generating
      # helpers prefixed with `organization_` (e.g. `organization_projects_path`).
      # Developers should use the standard (global) helpers instead (e.g.
      # `projects_path`), which automatically become organization-aware via
      # `Routing::OrganizationsHelper::MappedHelpers`.
      #
      # @example
      #
      #   # bad
      #   organization_root_path(org)
      #   organization_projects_url(namespace, organization_path: org.path)
      #   organization_project_issues_path(project, organization_path: org.path)
      #
      #   # good - standard helpers auto-redirect based on Current.organization
      #   root_path
      #   projects_url(namespace)
      #   project_issues_path(project)
      #
      #   # good - organization resource routes (not org-scoped clones)
      #   organization_path(org)
      #   organizations_path
      #   new_organization_path
      #
      class AvoidOrganizationUrlRoutes < RuboCop::Cop::Base
        MSG = 'Avoid direct use of organization-scoped URL helpers. ' \
          'Use the standard (global) route helper instead, which automatically becomes ' \
          'organization-aware. ' \
          'See https://docs.gitlab.com/development/organization/#organization-url-helpers.'

        # Matches org-scoped cloned route helpers like `organization_root_path`,
        # `organization_projects_url`, `organization_project_issues_path`.
        #
        # Does NOT match organization resource routes:
        # `organization_path`, `organization_url`, `organizations_path`, `new_organization_path`
        ORGANIZATION_ROUTE_PATTERN = /\Aorganization_\w+_(path|url)\z/

        def on_send(node)
          method_name = node.method_name.to_s
          return unless ORGANIZATION_ROUTE_PATTERN.match?(method_name)

          add_offense(node)
        end
        alias_method :on_csend, :on_send
      end
    end
  end
end
