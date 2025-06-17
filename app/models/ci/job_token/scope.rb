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
        if inbound_accessible?(accessed_project)
          # We capture only successful inbound authorizations
          Ci::JobToken::Authorization.capture(origin_project: current_project, accessed_project: accessed_project)
          true
        else
          # We observe failed authorization attempts using a Prometheus counter
          ::Gitlab::Ci::Pipeline::Metrics.job_token_authorization_failures_counter
          .increment(same_root_ancestor: same_root_ancestor?(accessed_project))
          false
        end
      end

      def policies_allowed?(accessed_project, policies)
        # We capture policies even if job token policies or allowlists are disabled, or the project is not allowlisted
        Ci::JobToken::Authorization.capture_job_token_policies(policies) if policies.present?

        return true unless accessed_project.job_token_policies_enabled?
        return true unless accessed_project.ci_inbound_job_token_scope_enabled?
        return false unless accessible?(accessed_project)

        policies_allowed_for_accessed_project?(accessed_project, policies)
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

      def autopopulated_group_ids
        inbound_allowlist.autopopulated_group_global_ids
      end

      def autopopulated_inbound_project_ids
        inbound_allowlist.autopopulated_project_global_ids
      end

      def self_referential?(accessed_project)
        current_project.id == accessed_project.id
      end

      private

      def inbound_accessible?(accessed_project)
        if accessed_project.ci_inbound_job_token_scope_enabled?
          ::Gitlab::Ci::Pipeline::Metrics.job_token_inbound_access_counter.increment(legacy: false)

          self_referential?(accessed_project) ||
            inbound_linked_as_accessible?(accessed_project) ||
            group_linked_as_accessible?(accessed_project)
        else
          ::Gitlab::Ci::Pipeline::Metrics.job_token_inbound_access_counter.increment(legacy: true)

          # if the setting is disabled any project is considered to be in scope.
          true
        end
      end

      def policies_allowed_for_accessed_project?(accessed_project, policies)
        scope = nearest_scope(accessed_project)
        return true if scope.nil? && self_referential?(accessed_project)
        return true if scope.default_permissions?
        return false if policies.empty?

        (policies - scope.expanded_job_token_policies).empty?
      end

      def nearest_scope(accessed_project)
        inbound_accessible_projects(accessed_project).nearest_scope_for_target_project(current_project)
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

      def same_root_ancestor?(accessed_project)
        current_project.root_ancestor == accessed_project.root_ancestor
      end
    end
  end
end
