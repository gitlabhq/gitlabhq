# frozen_string_literal: true

# This model represents the scope of access for a CI_JOB_TOKEN.
#
# A scope is initialized with a project.
#
# Projects can be added to the scope by adding ScopeLinks to
# create an allowlist of projects in either access direction (inbound, outbound).
#
# Currently, projects in the outbound allowlist can be accessed via the token
# in the source project.
#
# TODO(Issue #346298) Projects in the inbound allowlist can use their token to access
# the source project.
#
# CI_JOB_TOKEN should be considered untrusted without these features enabled.
#

module Ci
  module JobToken
    class Scope
      attr_reader :current_project

      def initialize(current_project)
        @current_project = current_project
      end

      def allows?(accessed_project)
        self_referential?(accessed_project) || outbound_allows?(accessed_project)
      end

      def outbound_projects
        outbound_allowlist.projects
      end

      # Deprecated: use outbound_projects, TODO(Issue #346298) remove references to all_project
      def all_projects
        outbound_projects
      end

      private

      def outbound_allows?(accessed_project)
        # if the setting is disabled any project is considered to be in scope.
        return true unless @current_project.ci_outbound_job_token_scope_enabled?

        outbound_allowlist.includes?(accessed_project)
      end

      def outbound_allowlist
        Ci::JobToken::Allowlist.new(@current_project, direction: :outbound)
      end

      def self_referential?(accessed_project)
        @current_project.id == accessed_project.id
      end
    end
  end
end
