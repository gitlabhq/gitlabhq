# frozen_string_literal: true

module Gitlab
  module Ai
    # Resolves the cascading AI "Custom instructions" for a Project or Group.
    #
    # Custom instructions are configured at the GROUP level only. This resolver
    # walks the group's ancestor chain and CONCATENATES every level so an agent
    # sees all applicable guidance. Entries are ordered from most-general to
    # most-specific (outermost group -> ... -> nearest group), so the most
    # specific instruction is read last:
    #
    #   [Group: top]        <text>
    #   [Group: top/sub]    <text>
    #
    # For a Project, the project's parent group chain is used (projects have no
    # instructions of their own). Blank levels are skipped. Returns an array of
    # [label, text] pairs.
    class CustomInstructionsResolver
      def initialize(resource)
        @resource = resource
      end

      def resolve
        group_entries
      end

      private

      attr_reader :resource

      def group_entries
        return [] unless group

        # Preload both associations the loop below reads: `namespace_settings`
        # (delegated to by `ai_custom_instructions`) and `route` (used by
        # `full_path`). Without this each ancestor triggers two extra queries.
        ancestors = group.self_and_ancestors(hierarchy_order: :desc)
          .with_namespace_settings
          .include_route

        ancestors.filter_map do |g|
          entry("Group: #{g.full_path}", g.ai_custom_instructions)
        end
      end

      # The group whose ancestor chain we walk: the resource itself when a Group,
      # or the project's parent group when a Project.
      def group
        @group ||=
          if resource.is_a?(Project)
            resource.group
          elsif resource.is_a?(Group)
            resource
          end
      end

      def entry(label, text)
        return if text.blank?

        [label, text.strip]
      end
    end
  end
end
