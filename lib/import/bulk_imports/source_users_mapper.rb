# frozen_string_literal: true

# This class is used by Gitlab::ImportExport::Base::RelationFactory when mapping
# users from the source to the destination.
#
# It is required that Import::SourceUser objects with source_user_identifier exists
# before executing Gitlab::ImportExport::Base::RelationFactory. The latter class was
# not modified to create Import::SourceUser if it does not exist since the class is
# also used by file based imports.
module Import
  module BulkImports
    class SourceUsersMapper
      include Gitlab::Utils::StrongMemoize

      # Gitlab::ImportExport::Base::RelationFactory expects member_mapper#map to
      # return an object that responds to []. For the other mappers a hash is
      # returned. In this case SourceUsersMapper#map returns a class that responds
      # to [].
      class MockedHash
        include Gitlab::Utils::StrongMemoize

        def initialize(source_user_mapper, source_ghost_user_id)
          @source_user_mapper = source_user_mapper
          @source_ghost_user_id = source_ghost_user_id
        end

        def [](user_identifier)
          return ghost_user_id if @source_ghost_user_id.to_s == user_identifier.to_s

          @source_user_mapper.find_source_user(user_identifier)&.mapped_user_id
        end

        def ghost_user_id
          Users::Internal.ghost.id
        end
        strong_memoize_attr :ghost_user_id
      end

      def initialize(context:)
        @context = context
      end

      def map
        @map ||= MockedHash.new(source_user_mapper, source_ghost_user_id)
      end

      def include?(user_identifier)
        !!map[user_identifier]
      end

      private

      attr_reader :context

      delegate :source_user_mapper, :source_ghost_user_id, to: :context
    end
  end
end
