# frozen_string_literal: true

module Types
  module Notes
    class DiscussionType < BaseObject
      graphql_name 'Discussion'

      authorize :read_note

      def self.authorization_scopes
        super + [:ai_workflows]
      end

      implements Types::Notes::BaseDiscussionInterface
      expose_permissions ::Types::PermissionTypes::Notes::Discussion

      field :noteable, Types::NoteableType, null: true,
        description: 'Object which the discussion belongs to.'
      field :notes, Types::Notes::NoteType.connection_type, null: false,
        description: 'All notes in the discussion.',
        max_page_size: 200
      field :truncated_diff_lines, [Types::Notes::DiffLineType], null: true,
        calls_gitaly: true,
        description: 'At most 16 highlighted diff lines above the diff note, ' \
          'up to and including the commented line. Null for non-diff discussions.'

      def truncated_diff_lines
        # Only diff discussions (DiffDiscussion) carry diff context; the base
        # Discussion / individual-note discussions do not respond to it.
        return unless object.diff_discussion?

        # Resolve the whole connection through one batch so the shared, memoized
        # `discussions_diffs` collection is highlighted in a single pass (and
        # reused from the highlight cache on repeat reads), instead of fanning
        # out one Gitaly highlight call per discussion node.
        BatchLoader::GraphQL.for(object).batch do |discussions, loader|
          discussions.group_by(&:context_noteable).each do |noteable, grouped|
            noteable.discussions_diffs.load_highlight if noteable.respond_to?(:discussions_diffs)

            grouped.each { |discussion| loader.call(discussion, discussion.truncated_diff_lines) }
          end
        end
      end

      def noteable
        noteable = object.noteable

        return unless Ability.allowed?(context[:current_user], :"read_#{noteable.to_ability_name}", noteable)

        # `noteable` is the `NoteableType` union. If its type is not one the union
        # can resolve, returning it raises mid-query (UnresolvedTypeError) and
        # surfaces to clients as an Internal server error -- failing the entire
        # request, even in a list like `User.events`. Return nil so the field is
        # simply absent for that one comment instead.
        return unless Types::NoteableType.resolvable?(noteable)

        noteable
      end
    end
  end
end
