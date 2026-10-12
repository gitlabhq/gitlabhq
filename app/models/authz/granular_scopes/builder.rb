# frozen_string_literal: true

module Authz
  module GranularScopes
    # Turns scope inputs into unsaved Authz::GranularScope records. The groups and projects
    # a selected_memberships input names by ID are loaded here; IDs that match no record are
    # dropped. It does not persist, deduplicate, or set organization_id.
    class Builder
      ResourceNotAllowedError = Class.new(StandardError)

      # @param inputs [Array<#[]>] one entry per requested scope, read with symbol keys:
      #   :access (Symbol|String), :permissions (Array<String>), and for selected_memberships
      #   :group_ids and :project_ids (Arrays of IDs, either may be missing)
      # @param boundary_rule [#allowed_resource?, #personal_projects_namespace] decides which
      #   resources may become boundaries and which namespace backs personal_projects
      def initialize(inputs, boundary_rule:)
        @inputs = inputs
        @boundary_rule = boundary_rule
      end

      # @return [Array<Authz::GranularScope>] one unsaved scope per boundary, in input order
      # @raise [ResourceNotAllowedError] on the first resource the rule refuses
      def build
        inputs.flat_map { |input| build_for(input) }
      end

      private

      attr_reader :inputs, :boundary_rule

      def build_for(input)
        base_attrs = { access: input[:access], permissions: input[:permissions] }

        case input[:access].to_sym
        when GranularScope::Access::SELECTED_MEMBERSHIPS
          load_resources(input).map do |resource|
            GranularScope.new(base_attrs.merge(namespace: namespace_for(resource)))
          end
        when GranularScope::Access::PERSONAL_PROJECTS
          [GranularScope.new(base_attrs.merge(namespace: boundary_rule.personal_projects_namespace))]
        else
          [GranularScope.new(base_attrs)]
        end
      end

      # Groups first, then projects, each with its project_namespace loaded so that
      # Boundary.for(project).namespace runs no query
      def load_resources(input)
        groups = ::Group.id_in(Array(input[:group_ids]))
        projects = ::Project.id_in(Array(input[:project_ids])).preload(:project_namespace)

        groups.to_a + projects.to_a
      end

      def namespace_for(resource)
        raise ResourceNotAllowedError unless boundary_rule.allowed_resource?(resource)

        Boundary.for(resource).namespace
      end
    end
  end
end
