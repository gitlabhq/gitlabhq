# frozen_string_literal: true

# This model represents the scope of access for a CI_JOB_TOKEN.
#
# A scope is initialized with a current project.
#
# Projects can be added to the scope by adding ScopeLinks to
# create an allowlist of projects in either access direction (inbound, outbound).
#
# Projects in the outbound allowlist can be accessed via the current project's job token.
#
# Projects in the inbound allowlist can use their project's job token to
# access the current project.
#
# CI_JOB_TOKEN should be considered untrusted without a scope enabled.
#

module Ci
  module JobToken
    class Scope
      attr_reader :current_project

      def initialize(current_project)
        @current_project = current_project
      end

      def accessible?(accessed_project)
        self_referential?(accessed_project) || (
          outbound_accessible?(accessed_project) &&
          inbound_accessible?(accessed_project)
        )
      end

      def outbound_projects
        outbound_allowlist.projects
      end

      def inbound_projects
        inbound_allowlist.projects
      end

      def inbound_projects_count
        inbound_projects.count
      end

      def groups
        inbound_allowlist.groups
      end

      def groups_count
        groups.count
      end

      private

      def outbound_accessible?(accessed_project)
        # if the setting is disabled any project is considered to be in scope.
        return true unless current_project.ci_outbound_job_token_scope_enabled?

        return true unless accessed_project.private?

        outbound_allowlist.includes_project?(accessed_project)
      end

      def inbound_accessible?(accessed_project)
        # if the setting is disabled any project is considered to be in scope.
        return true unless accessed_project.ci_inbound_job_token_scope_enabled?

        inbound_linked_as_accessible?(accessed_project) ||
          group_linked_as_accessible?(accessed_project)
      end

      # We don't check the inbound allowlist here. That is because
      # the access check starts from the current project but the inbound
      # allowlist contains projects that can access the current project.
      def inbound_linked_as_accessible?(accessed_project)
        inbound_accessible_projects(accessed_project).includes_project?(current_project)
      end

      def group_linked_as_accessible?(accessed_project)
        Ci::JobToken::Allowlist.new(accessed_project).includes_group?(current_project)
      end

      def inbound_accessible_projects(accessed_project)
        Ci::JobToken::Allowlist.new(accessed_project, direction: :inbound)
      end

      # User created list of projects allowed to access the current project
      def inbound_allowlist
        Ci::JobToken::Allowlist.new(current_project, direction: :inbound)
      end

      # User created list of projects that can be accessed from the current project
      def outbound_allowlist
        Ci::JobToken::Allowlist.new(current_project, direction: :outbound)
      end

      def self_referential?(accessed_project)
        current_project.id == accessed_project.id
      end
    end
  end
end
