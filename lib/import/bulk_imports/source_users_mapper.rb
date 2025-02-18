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
        def initialize(source_user_mapper)
          @source_user_mapper = source_user_mapper
        end

        def [](user_identifier)
          @source_user_mapper.find_source_user(user_identifier)&.mapped_user_id
        end
      end

      def initialize(context:)
        @context = context
      end

      def map
        @map ||= MockedHash.new(source_user_mapper)
      end

      def include?(user_identifier)
        !!map[user_identifier]
      end

      private

      attr_reader :context

      delegate :source_user_mapper, to: :context
    end
  end
end
