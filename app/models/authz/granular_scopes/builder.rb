# frozen_string_literal: true

module Authz
  module GranularScopes
    # Turns normalised scope inputs into unsaved Authz::GranularScope records.
    # It does not load records, persist, deduplicate, or set organization_id;
    # the caller owns loading, failure translation and attaching to an owner.
    class Builder
      ResourceNotAllowedError = Class.new(StandardError)

      # @param inputs [Array<Hash>] one entry per requested scope:
      #   { access: Symbol|String, permissions: Array<String>, resources: Array<Group, Project> }.
      #   `resources` is read only for selected_memberships and must hold loaded records.
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
          Array(input[:resources]).map do |resource|
            GranularScope.new(base_attrs.merge(namespace: namespace_for(resource)))
          end
        when GranularScope::Access::PERSONAL_PROJECTS
          [GranularScope.new(base_attrs.merge(namespace: boundary_rule.personal_projects_namespace))]
        else
          [GranularScope.new(base_attrs)]
        end
      end

      def namespace_for(resource)
        raise ResourceNotAllowedError unless boundary_rule.allowed_resource?(resource)

        Boundary.for(resource).namespace
      end
    end
  end
end
